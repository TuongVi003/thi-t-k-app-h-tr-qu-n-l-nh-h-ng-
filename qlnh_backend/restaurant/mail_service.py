import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

EMAIL_SENDER = "vi_2151220107@dau.edu.vn" 
APP_PASSWORD = "xclp glhg rtpz atpn"


def send_email(email_receiver, title, body):
    msg = MIMEMultipart()
    msg["From"] = EMAIL_SENDER
    msg["To"] = email_receiver
    msg["Subject"] = title
    msg.attach(MIMEText(body, "html"))

    try:
        # Kết nối tới Gmail SMTP server
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(EMAIL_SENDER, APP_PASSWORD)

        # Gửi email
        server.sendmail(EMAIL_SENDER, email_receiver, msg.as_string())
        print("✅ Email sent successfully!")

    except Exception as e:
        print(f"❌ Failed to send email: {e}")

    finally:
        server.quit()  # Đóng kết nối


def body_template(template_code, order_code, order_total, order_details):
    body = ""
    if template_code == "order_completion":
        body = f"""
        <h2>Order Confirmation - {order_code}</h2>
        <p>Thank you for your order! Here are the details:</p>
        <ul>
        {order_details}
        </ul>
        <p><strong>Total Amount: ${order_total:.2f}</strong></p>
        <p>We appreciate your business!</p>
    """
    
    return body


def generate_order_completion_email(order):
    """
    Tạo HTML email cho đơn hàng hoàn thành
    
    Args:
        order: Instance của model Order
        
    Returns:
        str: HTML content cho email
    """
    from restaurant.models import ChiTietOrder, HoaDon
    from django.utils import timezone
    
    # Lấy thông tin khách hàng
    customer_name = "Quý khách"
    customer_phone = ""
    if order.khach_hang:
        customer_name = order.khach_hang.ho_ten
        customer_phone = order.khach_hang.so_dien_thoai
    elif order.khach_vang_lai:
        customer_name = order.khach_vang_lai.ho_ten
        customer_phone = order.khach_vang_lai.so_dien_thoai
    
    # Lấy chi tiết order
    chi_tiet_items = ChiTietOrder.objects.filter(order=order)
    
    # Tạo danh sách món ăn
    order_items_html = ""
    subtotal = 0
    for item in chi_tiet_items:
        item_total = item.gia * item.so_luong
        subtotal += item_total
        order_items_html += f"""
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">{item.mon_an.ten_mon}</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: center;">{item.so_luong}</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right;">{item.gia:,.0f} ₫</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right; font-weight: 600;">{item_total:,.0f} ₫</td>
        </tr>
        """
    
    # Lấy hóa đơn (nếu có)
    try:
        hoa_don = HoaDon.objects.get(order=order)
        phi_giao_hang = hoa_don.phi_giao_hang
        tong_tien = hoa_don.tong_tien
        payment_method = dict(HoaDon._meta.get_field('payment_method').choices).get(hoa_don.payment_method, hoa_don.payment_method)
    except HoaDon.DoesNotExist:
        phi_giao_hang = order.calculate_shipping_fee() or 0
        tong_tien = subtotal + phi_giao_hang
        payment_method = "Chưa thanh toán"
    
    # Thông tin loại đơn và địa chỉ
    loai_order_display = "Ăn tại chỗ"
    dia_chi_info = ""
    if order.loai_order == 'takeaway':
        loai_order_display = "Mang về"
        if order.phuong_thuc_giao_hang == 'Giao hàng tận nơi' and order.dia_chi_giao_hang:
            dia_chi_info = f"""
            <tr>
                <td style="padding: 8px 0; color: #666;">
                    <strong>Địa chỉ giao hàng:</strong>
                </td>
                <td style="padding: 8px 0; text-align: right;">
                    {order.dia_chi_giao_hang}
                </td>
            </tr>
            """
    
    # Thông tin bàn (nếu có)
    ban_info = ""
    if order.ban_an:
        ban_info = f"""
        <tr>
            <td style="padding: 8px 0; color: #666;">
                <strong>Bàn số:</strong>
            </td>
            <td style="padding: 8px 0; text-align: right;">
                {order.ban_an.so_ban} ({order.ban_an.get_khu_vuc_display()})
            </td>
        </tr>
        """
    
    # Phí giao hàng (nếu có)
    phi_giao_hang_html = ""
    if phi_giao_hang > 0:
        phi_giao_hang_html = f"""
        <tr>
            <td colspan="3" style="padding: 12px; text-align: right; color: #666;">Phí giao hàng:</td>
            <td style="padding: 12px; text-align: right; font-weight: 600;">{phi_giao_hang:,.0f} ₫</td>
        </tr>
        """
    
    # Ghi chú (nếu có)
    ghi_chu_html = ""
    if order.ghi_chu:
        ghi_chu_html = f"""
        <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin-top: 20px; border-radius: 4px;">
            <p style="margin: 0; color: #856404;"><strong>Ghi chú:</strong> {order.ghi_chu}</p>
        </div>
        """
    
    # Thời gian
    order_time = order.order_time
    completed_time = timezone.now()
    
    # Template HTML chính
    html_content = f"""
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Đơn hàng hoàn thành</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
            <tr>
                <td align="center">
                    <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                        
                        <!-- Header -->
                        <tr>
                            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
                                <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600;">
                                    ✅ Đơn hàng hoàn thành
                                </h1>
                                <p style="margin: 10px 0 0 0; color: #ffffff; font-size: 16px; opacity: 0.9;">
                                    Cảm ơn bạn đã đặt hàng tại nhà hàng chúng tôi!
                                </p>
                            </td>
                        </tr>
                        
                        <!-- Content -->
                        <tr>
                            <td style="padding: 40px 30px;">
                                
                                <!-- Greeting -->
                                <p style="margin: 0 0 20px 0; font-size: 16px; color: #333;">
                                    Kính gửi <strong>{customer_name}</strong>,
                                </p>
                                
                                <p style="margin: 0 0 30px 0; font-size: 15px; color: #666; line-height: 1.6;">
                                    Đơn hàng của bạn đã được hoàn thành thành công. Dưới đây là chi tiết đơn hàng:
                                </p>
                                
                                <!-- Order Info -->
                                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 30px; background-color: #f8f9fa; border-radius: 8px; padding: 20px;">
                                    <tr>
                                        <td style="padding: 8px 0; color: #666;">
                                            <strong>Mã đơn hàng:</strong>
                                        </td>
                                        <td style="padding: 8px 0; text-align: right; font-weight: 600; color: #667eea;">
                                            #{order.id}
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #666;">
                                            <strong>Loại đơn:</strong>
                                        </td>
                                        <td style="padding: 8px 0; text-align: right;">
                                            {loai_order_display}
                                        </td>
                                    </tr>
                                    {ban_info}
                                    <tr>
                                        <td style="padding: 8px 0; color: #666;">
                                            <strong>Thời gian đặt:</strong>
                                        </td>
                                        <td style="padding: 8px 0; text-align: right;">
                                            {order_time.strftime('%d/%m/%Y %H:%M')}
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #666;">
                                            <strong>Hoàn thành lúc:</strong>
                                        </td>
                                        <td style="padding: 8px 0; text-align: right;">
                                            {completed_time.strftime('%d/%m/%Y %H:%M')}
                                        </td>
                                    </tr>
                                    {dia_chi_info}
                                    <tr>
                                        <td style="padding: 8px 0; color: #666;">
                                            <strong>Phương thức thanh toán:</strong>
                                        </td>
                                        <td style="padding: 8px 0; text-align: right;">
                                            {payment_method}
                                        </td>
                                    </tr>
                                </table>
                                
                                <!-- Order Items -->
                                <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #333; border-bottom: 2px solid #667eea; padding-bottom: 10px;">
                                    Chi tiết món ăn
                                </h2>
                                
                                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 20px;">
                                    <thead>
                                        <tr style="background-color: #f8f9fa;">
                                            <th style="padding: 12px; text-align: left; font-size: 14px; color: #666; border-bottom: 2px solid #e0e0e0;">Món ăn</th>
                                            <th style="padding: 12px; text-align: center; font-size: 14px; color: #666; border-bottom: 2px solid #e0e0e0;">SL</th>
                                            <th style="padding: 12px; text-align: right; font-size: 14px; color: #666; border-bottom: 2px solid #e0e0e0;">Đơn giá</th>
                                            <th style="padding: 12px; text-align: right; font-size: 14px; color: #666; border-bottom: 2px solid #e0e0e0;">Thành tiền</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {order_items_html}
                                    </tbody>
                                    <tfoot>
                                        <tr>
                                            <td colspan="3" style="padding: 12px; text-align: right; color: #666;">Tạm tính:</td>
                                            <td style="padding: 12px; text-align: right; font-weight: 600;">{subtotal:,.0f} ₫</td>
                                        </tr>
                                        {phi_giao_hang_html}
                                        <tr style="background-color: #f8f9fa;">
                                            <td colspan="3" style="padding: 15px; text-align: right; font-size: 18px; font-weight: 600; color: #333;">Tổng cộng:</td>
                                            <td style="padding: 15px; text-align: right; font-size: 20px; font-weight: 700; color: #667eea;">{tong_tien:,.0f} ₫</td>
                                        </tr>
                                    </tfoot>
                                </table>
                                
                                {ghi_chu_html}
                                
                                <!-- Thank you message -->
                                <div style="background-color: #e8f5e9; border-left: 4px solid #4caf50; padding: 15px; margin-top: 30px; border-radius: 4px;">
                                    <p style="margin: 0; color: #2e7d32; font-size: 15px; line-height: 1.6;">
                                        💚 Cảm ơn bạn đã tin tưởng và sử dụng dịch vụ của chúng tôi. Chúng tôi rất mong được phục vụ bạn lần sau!
                                    </p>
                                </div>
                                
                            </td>
                        </tr>
                        
                        <!-- Footer -->
                        <tr>
                            <td style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e0e0e0;">
                                <p style="margin: 0 0 10px 0; font-size: 16px; font-weight: 600; color: #333;">
                                    Nhà hàng Moon
                                </p>
                                <p style="margin: 0 0 5px 0; font-size: 14px; color: #666;">
                                    📞 Hotline: 1900-xxxx
                                </p>
                                <p style="margin: 0 0 5px 0; font-size: 14px; color: #666;">
                                    📧 Email: vi_2151220107@dau.edu.vn
                                </p>
                                <p style="margin: 0; font-size: 14px; color: #666;">
                                    📍 Địa chỉ: 248 Núi Thành, Hòa Cường Nam, Đà Nẵng
                                </p>
                                
                                <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
                                    <p style="margin: 0; font-size: 12px; color: #999;">
                                        Email này được gửi tự động, vui lòng không trả lời.
                                    </p>
                                </div>
                            </td>
                        </tr>
                        
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    """
    
    return html_content


def send_order_completion_email(order):
    """
    Gửi email thông báo đơn hàng hoàn thành cho khách hàng
    
    Args:
        order: Instance của model Order
        
    Returns:
        bool: True nếu gửi thành công, False nếu thất bại
    """
    # Lấy email khách hàng
    email_receiver = None
    customer_name = "Quý khách"
    
    if order.khach_hang and hasattr(order.khach_hang, 'email') and order.khach_hang.email:
        email_receiver = order.khach_hang.email
        customer_name = order.khach_hang.ho_ten
    elif order.khach_vang_lai and hasattr(order.khach_vang_lai, 'email') and order.khach_vang_lai.email:
        email_receiver = order.khach_vang_lai.email
        customer_name = order.khach_vang_lai.ho_ten
    
    if not email_receiver:
        print(f"⚠️ Không có email cho đơn hàng #{order.id}")
        return False
    
    # Tạo email content
    html_body = generate_order_completion_email(order)
    title = f"🎉 Đơn hàng #{order.id} đã hoàn thành - Nhà hàng Moon"
    
    # Gửi email
    try:
        send_email(email_receiver, title, html_body)
        print(f"✅ Đã gửi email hoàn thành đơn hàng #{order.id} đến {email_receiver}")
        return True
    except Exception as e:
        print(f"❌ Lỗi gửi email cho đơn hàng #{order.id}: {e}")
        return False
