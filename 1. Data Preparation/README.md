# 1. Data Preparation

## Dataset Overview

The dataset `02_Email_CRM_Campaign.xlsx` contains email and CRM campaign records tracking customer engagement from initial send through conversion.

## Data Fields

| Field | Type | Description |
|-------|------|-------------|
| `Campaign_ID` | String | Unique campaign identifier |
| `Campaign_Name` | String | Name of the email campaign |
| `Campaign_Type` | String | Welcome, Newsletter, Promotional, Re-engagement, etc. |
| `Customer_Segment` | String | Target audience segment |
| `Send_Date` | Date | Date campaign was sent |
| `Emails_Sent` | Integer | Total emails sent |
| `Emails_Delivered` | Integer | Successfully delivered emails |
| `Emails_Opened` | Integer | Unique email opens |
| `Clicks` | Integer | Total link clicks |
| `Conversions` | Integer | Purchases/actions completed |
| `Revenue_VND` | Float | Revenue attributed to campaign |
| `Unsubscribes` | Integer | Unsubscribe count |
| `Bounces` | Integer | Hard + soft bounce count |
| `Spam_Reports` | Integer | Spam complaint count |
| `Open_Rate_Pct` | Float | Open rate (%) |
| `CTR_Pct` | Float | Click-through rate (%) |
| `Conv_Rate_Pct` | Float | Conversion rate (%) |
| `Revenue_Per_Email` | Float | Revenue generated per email sent |
| `Subject_Line` | String | Email subject line |
| `Send_Time` | String | Time of day email was sent |
| `Device_Type` | String | Mobile, Desktop, Tablet |
