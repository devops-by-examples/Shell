import smtplib
import psutil

# 1. Check the CPU usage
cpu_usage = psutil.cpu_percent(interval=1)

# 2. Trigger email if it exceeds the limit
if cpu_usage > 80.0:
    # Setup the connection
    server = smtplib.SMTP('://gmail.com', 587)
    server.starttls()
    server.login('abc@gmail.com', 'password')
    
    # Send the raw message
    subject = "Subject: CPU Alert\n\n"
    body = f"CPU usage is high: {cpu_usage}%"
    server.sendmail('abc@gmail.com', 'owner_of_vm@gmail.com', subject + body)
    
    server.quit()
