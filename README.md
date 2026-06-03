# 💰 Loan Management System (LMS) iOS App

A modern, highly secure, and role-based Loan Management System built with **SwiftUI** and powered by **Supabase**. Designed to digitize the entire lending lifecycle—from application and document verification to final disbursement, repayment tracking, and auditing—for Borrowers, Loan Officers, Bank Managers, and Admins.

<p align="center">
  <img src="docs/images/app-banner.png" alt="Loan Management System Banner" width="100%">
</p>

![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green)
![Backend](https://img.shields.io/badge/Backend-Supabase-emerald)
![Payments](https://img.shields.io/badge/Payments-Razorpay-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 📖 Overview

The Loan Management System (LMS) is a complete, scalable digital lending platform. By adopting a strict **Role-Based Access Control (RBAC)** model, it securely delegates tasks across different staff members while providing borrowers with a beautifully designed, intuitive portal to track their financial health.

Built with **SwiftUI**, **MVVM Architecture**, and **Supabase (PostgreSQL, Auth, Storage, Realtime)**, the application ensures high performance, real-time data sync, and enterprise-grade security.

### 🎯 Key Objectives

* **Zero-Paper Workflow**: 100% digital KYC and document processing.
* **Role-Specific Dashboards**: Tailored UI/UX for Borrowers, Officers, Managers, and Admins.
* **Real-time Pipeline**: Live tracking of applications as they move through underwriting.
* **Integrated Payments**: Seamless EMI repayment gateway using Razorpay.
* **Data-Driven Insights**: Advanced analytics and CSV report generation for management.

---

## ✨ Features by Role

### 👤 Customer (Borrower)
* **Onboarding & Auth**: Secure login, Biometric (Face ID) app lock, and dynamic KYC onboarding.
* **Loan Wizard**: Multi-step, interactive loan application flow with form validation.
* **Document Vault**: Securely upload and manage KYC, income proofs, and property documents.
* **Repayment Dashboard**: Real-time EMI tracking, upcoming dues, and Razorpay-powered instant payments.
* **Support Hub**: Real-time chat with assigned Loan Officers.
* **Push Notifications**: Live updates on application status and payment reminders.

### 💼 Loan Officer
* **Action-Oriented Dashboard**: Prioritized daily task lists and pipeline metrics.
* **Document Verification**: In-app document viewer (PDF/Images) with one-tap approve/reject flagging.
* **Borrower Communication**: Direct chat interface to request missing documents or clarify details.
* **Application Routing**: Forward verified applications to Bank Managers or escalate edge cases.
* **Inline EMI Calculators**: Quick tools to calculate affordability during borrower consultations.

### 🏦 Bank Manager
* **Approval Workflow**: Final review authority with complete audit trails of Officer actions.
* **Team Monitoring**: Track performance metrics across the Loan Officer team (disbursed vs. rejected).
* **Advanced Analytics**: Visual charts for portfolio health, NPA analysis, and branch performance.
* **Report Generation**: Export live system data to CSV for external audits.

### 👨‍💻 System Administrator
* **Global Configuration**: Manage system-wide loan rules (min CIBIL, max DTI, max LTV).
* **Product Management**: Dynamically create and adjust loan products (Home, Auto, Personal) and their interest rates.
* **Staff Management**: Provision new Loan Officers and Managers and assign branch access.

---

## 🏗️ Architecture & Tech Stack

The application strictly adheres to the **MVVM (Model-View-ViewModel)** architectural pattern, ensuring separation of concerns and high testability.

### Frontend (iOS)
* **Framework**: SwiftUI (iOS 17+)
* **Concurrency**: Swift Async/Await & Actors (`@MainActor`)
* **State Management**: Combine (`@Published`, `ObservableObject`), `@EnvironmentObject`
* **UI/UX**: Custom Glassmorphism, Micro-animations, SF Symbols, Charts framework.
* **Intents**: AppIntents integration for Siri and Spotlight search.

### Backend (Supabase)
* **Database**: PostgreSQL with strict Row Level Security (RLS).
* **Auth**: Supabase Auth (Email/Password) with JWTs.
* **Storage**: Supabase Storage for secure PDF and Image document hosting.
* **Realtime**: WebSockets for live chat and instant notification delivery.

### Third-Party Integrations
* **Payments**: Razorpay iOS SDK (Sandbox) for processing EMI transactions.
* **Networking**: Native `URLSession` combined with `supabase-swift`.

---

## 🚀 Getting Started

### Prerequisites

* **Xcode**: Version 15.0 or higher
* **iOS Target**: iOS 17.0+
* **Swift**: Version 5.9+
* **Supabase Project**: A configured Supabase backend.
* **Razorpay Account**: Test API keys for the payment gateway.

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/loan-management-system.git
   cd loan-management-system
   ```

2. **Open the Project**
   ```bash
   open LoanManagementSystem.xcodeproj
   ```

3. **Configure Environment Variables**
   Locate `AppConfiguration.swift` and update it with your Supabase and Razorpay credentials:
   ```swift
   enum AppConfiguration {
       static let supabaseURL = URL(string: "https://YOUR_SUPABASE_PROJECT.supabase.co")!
       static let supabaseAnonKey = "YOUR_ANON_KEY"
       static let razorpayKey = "YOUR_RAZORPAY_TEST_KEY"
   }
   ```

4. **Resolve Dependencies**
   Xcode will automatically resolve Swift Package Manager (SPM) dependencies (Supabase, Razorpay).

5. **Build & Run**
   Select your preferred Simulator or Physical Device and press **⌘ + R**.

---

## 🔄 Loan Processing Lifecycle

```text
Draft Application
        │
        ▼
Under Review (Officer) ───▶ Request Missing Docs ───▶ Back to Review
        │
        ▼
Manager Final Review
        │
        ├──▶ Rejected
        │
        ▼
Approved & Disbursed
        │
        ▼
Active Repayment (EMI via Razorpay)
        │
        ▼
Loan Closed
```

---

## 🔐 Security & Privacy

* **Row Level Security (RLS)**: Database tables are strictly protected so users can only access their own data, and officers can only access assigned cases.
* **Main Thread Safety**: Robust implementation of `@MainActor` to prevent background UI crashes during heavy data syncs.
* **On-Device Biometrics**: Optional Face ID / Touch ID gatekeeping upon app launch.

---

## 👨‍💻 Developed By

Built to demonstrate advanced modern iOS development and robust backend-as-a-service integration.
