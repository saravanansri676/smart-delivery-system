package com.example.demo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void sendOTP(String toEmail, String otp, String purpose) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(toEmail);
            message.setSubject("Smart Delivery System - OTP Verification");
            message.setText(
                    "Dear Manager,\n\n" +
                            "Your OTP for " + purpose + " is: " + otp + "\n\n" +
                            "This OTP is valid for 5 minutes.\n\n" +
                            "Do not share this OTP with anyone.\n\n" +
                            "Regards,\nSmart Delivery System"
            );
            mailSender.send(message);
            System.out.println("OTP sent to: " + toEmail);
        } catch (Exception e) {
            System.out.println("Email error: " + e.getMessage());
        }
    }
}