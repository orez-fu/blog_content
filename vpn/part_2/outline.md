# Metadata

- Thời gian đọc mục tiêu: 6-10 phút
- Tag: devops, aws, vpn, sre

# Outline

Section 0: Mở đầu

- Recap ngắn phần 1:
    - Đã triển khai OpenVPN Access Server trên AWS
    - Kiến trúc đơn giản: 1 VPC, 1 public subnet + 1 public EC2, 1 private subnet + 1 private EC2
    - Chỉ có 1 user và 1 access rule `10.0.0.0/16`
- Đặt vấn đề:
    - Trong thực tế, hạ tầng không chỉ có EC2
    - Có RDS, có MSK, có Lambda, có EKS, có cả các internal services(Grafana, RKE2)
    - Có nhiều team DBA, Developer, DevOps, SRE - mỗi team cần truy cập resource khác nhau
    - Câu hỏi: Làm sao kiểm soát “ai được truy cập gì” qua VPN?
- Mục tiêu phần 2:
    - Hiểu cơ chế Access Control trong OpenVPN Access Server
    - Harderning Security Group & Network ACL
    - Mở rộng hạ tầng: thêm RDS, EKS, Lambda
    - Demo: phân quyền truy cập cho các team khác nhau

Section 1 - Kiến trúc mở rộng

1. Phạm vi demo:
    
    Phần thực hành tập trung vào:
    
    - OpenVPN Access Server
    - RDS MySQL
    - EKS Cluster
    - Grafana cài đặt trong EKS
    - Rancher cài đặt trong EKS
    - ArgoCD cài đặt trong EKS
    - Internal Application Load Balancer
    - Lambda function phía sau ALB.
2. Kịch bản mô phỏng:
    - Một công ty có 3 team cần truy cập hạ tầng AWS qua VPN
        
        
        | Team | Nhu cầu truy cập | Resource |
        | --- | --- | --- |
        | DBA | Quản trị database, troubleshoot query,… | RDS |
        | Developer | Phát triển, debug, quan sát ứng dụng | Rancher, Grafana, Internal ALB |
        | DevOps/SRE | Full access để vận hành | Toàn bộ resource trong VPC |
    - Trong đó Yêu cầu:
        - DBA chỉ truy cập:
            - resolve RDS endpoint
            - kết nối RDS trên đúng database port
            - sử dụng database credential tương ứng.
        - Developer:
            - Rancher UI
            - ArgoCD
            - Grafana
            - Gọi private API thông qua Internal ALB
        - SRE được phép:
            - Truy cập RDS
            - Quản trị Rancher
            - Truy cập EKS private endpoint
            - Truy cập Grafana và internal ALB
            - Cùng các resource khác quản lý trên AWS VPC.

Thêm sơ đồ luồng làm việc của 3 teams.

1. Sơ đồ kiến trúc AWS

Thêm sơ đồ kiến trúc ở đây.

1. Tài nguyên AWS bổ sung
    - Liệt kê các resource cần tạo thêm so với phần 1:
        - RDS instance (MySQL) trong private subnet
        - EKS cluster với private API endpoint
        - Subnet groups cho RDS và EKS
        - Security Groups cho từng resource
        - Lambda, Internal ALB như các pattern tương tự
        - Các ứng dụng internal
    - Tách CIDR: OpenVPN Access Control chủ yếu phân quyền theo network/CIDR → tách trust zone giúp network access phản ánh đúng vai trò của từng team.

Section 2 - Access Control trong OpenVPN Access Server

1. Tổng quan cơ chế Access Control
    - Giải thích mô hình phân quyền
        - OpenVPN AS kiểm soát truy cập ở 2 lớp
            - Lớp 1: Authentication
            - Lớp 2: Authorization
        - Access Control trong OpenVPN AS = kiểm soát route nào được push cho user nào
    - So sánh với cách làm cổ điển
        - Truyền thống: mở VPN →  access toàn bộ network (flat access)
        - Đúng cách: mở VPN → chỉ access subnet/ip resource được cho phép (least priviledge)
2. Access Rules - cách rule hoạt động
    - Giải thích cấu trúc Access Rule trong OpenAccess AS
        - Mỗi rule gắn với 1 user hoặc group
        - Rule định nghĩa: CIDR nào user được phép truy cập
        - khi user kết nối VPN → server chỉ push route cho các CIDR được allow
        - Traffic tới CIDR khác sẽ không đi qua VPN tunnel (split tunnel)
    - Thứ tự ưu tiên:
        - User-level rule > Group-level rule
        - Explicit deny > allow
    - Ví dụ minh họa kèm theo
        - dba-user …
        - dev-user …
        - sre-user …
3. Cấu hình qua Admin UI
    
    Hướng dẫn từng bước trên Admin UI
    

Section 3 - Hardening Security Group & Network ACL

1. Thiết kế Security Group theo nguyen tắc Least Priviledge
    - SG cho OpenVPN Access Server
    - SG cho RDS
    - SG cho EKS worker nodes
    - SG cho Internal ALB Securigy Group
    - Nguyên tắc quan trọng: Reference Security bằng SG ID, không dùng IP cứng
2. Network ACL - Defense in Depth
    - Vai trò: lớp bảo vệ bổ sung ở subnet level
    - Đặc điểm khác SG
        - Stateless
        - Áp dụng cho toàn bộ subnet
        - Rule number
    - NACL cho private subnet RDS, EKS,…
    
    (Chỉ trình bày NACL như lớp defense in depth và giữ default NACL cho demo chính)
    
    - DNS cho private endpoints: có các hostname cần resolve như RDS endpoint, internal ALB DNS name, Rancher hostname, Grafana private domain, EKS private endpoint.

Section 4 - Demo thực hành

1. Chuẩn bị hạ tầng
    - Terraform mở rộng, cung cấp source code tải về tương tự phần 1
2. Tạo user và cấu hình Access Control
    - Trên Admin UI kèm screen shot minh họa
3. Test kết nối tới RDS
    - Login VPN với dba-user
    - Verify route table
    - kết nối database bằng DBeaver
    - Kiếm tra kết nối tới tài nguyên khác
    - …
4. Test kết nối tới EKS
    - Login VPN
    - Verify route table
    - Cấu hình kubectl
    - Xử lý DNS resolution cho EKS private endpoint
    - Kiểm chứng phân quyền khác
    - …

Section 5 - Kết luận

- Tổng kết những gì đã thực hiện
    - mở rộng kiến trúc AWS
    - Cấu hình Access Control phân quyền theo team/user
    - Hardening SG + NACL theo nguyên tắc least priviledge
    - Kiểm chứng: đúng user, đúng resource
- Lưu ý về layer security AWS network enforcement và Service authorization, được chi tiết khi triển khai AWS và vận hành ứng dụng.
- Preview phần tiếp theo: gới ý về Monitoring & Logging cho VPN
- …