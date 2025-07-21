# 🛰️ Event-Driven Data Processing Pipeline on AWS

This project showcases a fully automated, serverless, event-driven data pipeline built using AWS services. I designed, implemented, and deployed this pipeline to collect incoming data via an API, store it in S3, run daily analytics using Athena, and automatically email summary reports using SES. All infrastructure is provisioned using Terraform, and CI/CD is handled through GitHub Actions.

---

## 🚀 What I Built

### 🔗 1. **API Gateway + Lambda for Data Ingestion**
- I configured **API Gateway (HTTP)** to expose a public `/ingest` endpoint.
- I wrote a **Lambda function** that receives JSON payloads and stores them in a structured format in **Amazon S3**.

### 🗃️ 2. **S3 Bucket for Raw Data**
- I created an S3 bucket (`event-pipeline-storage`) to persist incoming data.
- I configured Lambda with the necessary **IAM permissions** to write to S3 without any access errors.

### 🧠 3. **Athena + Glue for Querying**
- I configured **AWS Glue Data Catalog** and crawlers to catalog the S3 data.
- I wrote **Athena SQL queries** to compute daily summaries over the ingested data.

### 📨 4. **Lambda + SES for Daily Reports**
- I developed a second Lambda function that:
  - Queries Athena
  - Formats the result
  - Sends summary emails via **AWS SES**
- I handled SES sandbox restrictions by verifying email identities.

### ⏰ 5. **CloudWatch Scheduler**
- I created a **CloudWatch Event Rule** to invoke the report Lambda **daily**.
- I ensured proper **IAM role permissions** for event invocation.

### 🧱 6. **Infrastructure as Code (IaC) with Terraform**
- I wrote the entire infrastructure in **Terraform**, covering:
  - API Gateway
  - Lambda functions
  - IAM roles and policies
  - S3, Athena, SES, CloudWatch

### 🔁 7. **CI/CD with GitHub Actions**
- I implemented **CI/CD** using GitHub Actions:
  - On every push to `main`, Terraform is automatically initialized, planned, and applied.
  - Secrets are stored securely in **GitHub Secrets** for AWS credentials.

---

## 🧪 How to Use

### ✅ Trigger the Pipeline

Send a POST request to the API Gateway endpoint:

```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/ingest \
  -H "Content-Type: application/json" \
  -d '{"user_id": "123", "action": "login", "timestamp": "2025-07-21T14:00:00Z"}'
```
---

📬 Receive Daily Reports
Reports are emailed once a day.

You can customize the Athena query or SES content in report_lambda.py.

---
📂 Project Structure

```
python
Copy
Edit
.
├── terraform/                 # Terraform IaC for AWS resources
├── lambda/
│   ├── lambda_function.py     # Ingest Lambda
│   └── report_lambda.py       # Report Lambda
├── .github/workflows/
│   └── deploy.yml             # GitHub Actions for CI/CD
├── lambda.zip                 # Packaged ingest Lambda
├── report_lambda.zip          # Packaged report Lambda
└── README.md                  # This file

```
---

### 🔐 AWS Permissions
I ensured proper AWS permissions using:

lambda_exec_role for Lambda

lambda_s3_write_policy for ingesting data

athena-ses-lambda-policy for querying + emailing
---

### 📬 SES Configuration
Verified sender and recipient addresses in SES sandbox

To go production-ready, request SES production access via AWS Support

---

### 💡 What I Learned
### ✅ Deep hands-on experience with:

AWS Lambda, S3, Athena, SES, CloudWatch Events

Terraform modules and state management

CI/CD pipelines using GitHub Actions

Debugging IAM, API Gateway, and SES restrictions

Managing AWS infrastructure with a reproducible, automated pipeline

🙌 Acknowledgments
This project was developed as part of a cloud engineering assignment, and I'm proud to have fully automated and deployed the complete system end-to-end within a tight timeframe.
