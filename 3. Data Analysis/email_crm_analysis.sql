-- =============================================================================
-- Email CRM Marketing — SQL Analysis
-- Dataset : 02_Email_CRM_Marketing - 2_CLEANED_DATA.csv
-- Dialect : Standard SQL (PostgreSQL / BigQuery / DuckDB compatible)
-- Date    : 2026-05-17
-- =============================================================================
-- HOW TO USE (DuckDB / local):
--   duckdb -c "CREATE TABLE email_campaigns AS
--              SELECT * FROM read_csv_auto(
--                '02_Email_CRM_Marketing - 2_CLEANED_DATA.csv',
--                header=true, all_varchar=false);"
--   Then run the queries below.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Schema Reference
-- ---------------------------------------------------------------------------
-- Email_ID, Campaign_Name, Campaign_Type, Brand, Vertical, CRM_Stage,
-- Target_Segment, Campaign_Manager, Send_Date, Send_Day, Send_Hour,
-- Month, Quarter, Subject_Line, Subject_Length,
-- Has_Personalization, Has_Emoji_Subject, AB_Test, Winning_Variant,
-- Automation_Trigger, Primary_Device, Top_Email_Client, Status,
-- List_Size, Emails_Sent, Emails_Delivered,
-- "Delivery_Rate_%", Hard_Bounces, Soft_Bounces, "Bounce_Rate_%",
-- Emails_Opened, "Open_Rate_%", Unique_Opens, Clicks, "CTR_%", "CTOR_%",
-- Unsubscribes, "Unsub_Rate_%", Spam_Complaints, "Spam_Rate_%",
-- Conversions, "Conv_Rate_%", Revenue_VND, Revenue_per_Email_VND
-- ---------------------------------------------------------------------------


-- ===========================================================================
-- SECTION 0 — OVERALL KPIs
-- ===========================================================================

SELECT
    COUNT(*)                                      AS total_campaigns,
    ROUND(SUM(Emails_Sent)        / 1e6, 2)       AS total_sent_M,
    ROUND(SUM(Emails_Delivered)   / 1e6, 2)       AS total_delivered_M,
    ROUND(SUM(Revenue_VND)        / 1e9, 2)       AS total_revenue_B_VND,
    ROUND(AVG("Delivery_Rate_%"),  2)             AS avg_delivery_pct,
    ROUND(AVG("Bounce_Rate_%"),    2)             AS avg_bounce_pct,
    ROUND(AVG("Open_Rate_%"),      2)             AS avg_open_rate_pct,
    ROUND(AVG("CTR_%"),            2)             AS avg_ctr_pct,
    ROUND(AVG("CTOR_%"),           2)             AS avg_ctor_pct,
    ROUND(AVG("Conv_Rate_%"),      2)             AS avg_conv_rate_pct,
    ROUND(AVG("Unsub_Rate_%"),     2)             AS avg_unsub_pct,
    ROUND(AVG("Spam_Rate_%"),      4)             AS avg_spam_pct,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email_VND
FROM email_campaigns;


-- ===========================================================================
-- BQ1 — CAMPAIGN TYPE PERFORMANCE (ranked by Revenue)
-- ===========================================================================

SELECT
    Campaign_Type,
    COUNT(*)                                      AS campaigns,
    ROUND(SUM(Emails_Sent)     / 1e6, 2)          AS sent_M,
    ROUND(SUM(Revenue_VND)     / 1e9, 2)          AS revenue_B_VND,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email,
    ROUND(AVG("Open_Rate_%"),   2)                AS avg_open_pct,
    ROUND(AVG("CTR_%"),         2)                AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),   2)                AS avg_conv_pct,
    ROUND(AVG("Unsub_Rate_%"),  2)                AS avg_unsub_pct,
    ROUND(AVG("Bounce_Rate_%"), 2)                AS avg_bounce_pct
FROM email_campaigns
GROUP BY Campaign_Type
ORDER BY revenue_B_VND DESC;


-- ===========================================================================
-- BQ1b — EMAIL FUNNEL BY CAMPAIGN TYPE
-- ===========================================================================

SELECT
    Campaign_Type,
    ROUND(SUM(Emails_Sent)      / 1e6, 2)         AS sent_M,
    ROUND(SUM(Emails_Delivered) / 1e6, 2)         AS delivered_M,
    ROUND(SUM(Emails_Opened)    / 1e6, 2)         AS opened_M,
    ROUND(SUM(Clicks)           / 1e3, 2)         AS clicks_K,
    ROUND(SUM(Conversions)      / 1e3, 2)         AS conversions_K,
    ROUND(100.0 * SUM(Emails_Opened) / NULLIF(SUM(Emails_Delivered), 0), 2) AS delivered_to_open_pct,
    ROUND(100.0 * SUM(Clicks)   / NULLIF(SUM(Emails_Opened), 0),        2) AS open_to_click_pct,
    ROUND(100.0 * SUM(Conversions) / NULLIF(SUM(Clicks), 0),            2) AS click_to_conv_pct
FROM email_campaigns
GROUP BY Campaign_Type
ORDER BY conversions_K DESC;


-- ===========================================================================
-- BQ2 — SEND TIMING: DAY OF WEEK
-- ===========================================================================

SELECT
    Send_Day,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email
FROM email_campaigns
GROUP BY Send_Day
ORDER BY avg_conv_pct DESC;


-- ===========================================================================
-- BQ2b — SEND TIMING: HOUR OF DAY (bucketed)
-- ===========================================================================

SELECT
    CASE
        WHEN Send_Hour BETWEEN  6 AND  8 THEN '06-09h (Morning)'
        WHEN Send_Hour BETWEEN  9 AND 11 THEN '09-12h (Late Morning)'
        WHEN Send_Hour BETWEEN 12 AND 14 THEN '12-15h (Afternoon)'
        WHEN Send_Hour BETWEEN 15 AND 17 THEN '15-18h (Late Afternoon)'
        WHEN Send_Hour BETWEEN 18 AND 20 THEN '18-21h (Evening)'
        ELSE                                  'Other'
    END                                           AS hour_bucket,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email
FROM email_campaigns
GROUP BY hour_bucket
ORDER BY avg_conv_pct DESC;


-- ===========================================================================
-- BQ3 — PERSONALIZATION & FEATURE IMPACT
-- ===========================================================================

-- 3a. Personalization
SELECT
    Has_Personalization,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email
FROM email_campaigns
GROUP BY Has_Personalization;

-- 3b. Emoji in Subject
SELECT
    Has_Emoji_Subject,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct
FROM email_campaigns
GROUP BY Has_Emoji_Subject;

-- 3c. A/B Testing
SELECT
    AB_Test,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND
FROM email_campaigns
GROUP BY AB_Test;

-- 3d. Subject length impact (bucketed)
SELECT
    CASE
        WHEN Subject_Length <= 20 THEN '≤20 chars (Short)'
        WHEN Subject_Length <= 35 THEN '21-35 chars (Medium)'
        WHEN Subject_Length <= 50 THEN '36-50 chars (Long)'
        ELSE                          '>50 chars (Very Long)'
    END                                           AS subject_length_bucket,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct
FROM email_campaigns
GROUP BY subject_length_bucket
ORDER BY avg_open_pct DESC;


-- ===========================================================================
-- BQ4 — CRM STAGE ANALYSIS
-- ===========================================================================

SELECT
    CRM_Stage,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND,
    ROUND(AVG("Unsub_Rate_%"), 2)                 AS avg_unsub_pct,
    ROUND(AVG("Bounce_Rate_%"),2)                 AS avg_bounce_pct,
    ROUND(SUM(Conversions)  / 1e3, 2)             AS conversions_K
FROM email_campaigns
GROUP BY CRM_Stage
ORDER BY revenue_B_VND DESC;


-- ===========================================================================
-- BQ5 — BRAND PERFORMANCE
-- ===========================================================================

SELECT
    Brand,
    COUNT(*)                                      AS campaigns,
    ROUND(SUM(Emails_Sent)     / 1e6, 2)          AS sent_M,
    ROUND(SUM(Revenue_VND)     / 1e9, 2)          AS revenue_B_VND,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email,
    ROUND(AVG("Open_Rate_%"),   2)                AS avg_open_pct,
    ROUND(AVG("CTR_%"),         2)                AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),   2)                AS avg_conv_pct,
    ROUND(AVG("Unsub_Rate_%"),  2)                AS avg_unsub_pct
FROM email_campaigns
GROUP BY Brand
ORDER BY revenue_B_VND DESC;


-- ===========================================================================
-- BQ6 — TARGET SEGMENT EFFECTIVENESS
-- ===========================================================================

SELECT
    Target_Segment,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND,
    ROUND(AVG("Unsub_Rate_%"), 2)                 AS avg_unsub_pct,
    ROUND(AVG("Bounce_Rate_%"),2)                 AS avg_bounce_pct
FROM email_campaigns
GROUP BY Target_Segment
ORDER BY avg_conv_pct DESC;


-- ===========================================================================
-- BQ7 — MONTHLY & QUARTERLY TRENDS
-- ===========================================================================

-- 7a. Monthly
SELECT
    Month,
    COUNT(*)                                      AS campaigns,
    ROUND(SUM(Emails_Sent)     / 1e6, 2)          AS sent_M,
    ROUND(SUM(Revenue_VND)     / 1e9, 2)          AS revenue_B_VND,
    ROUND(AVG("Open_Rate_%"),   2)                AS avg_open_pct,
    ROUND(AVG("CTR_%"),         2)                AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),   2)                AS avg_conv_pct
FROM email_campaigns
GROUP BY Month
ORDER BY Month;

-- 7b. Quarterly
SELECT
    Quarter,
    COUNT(*)                                      AS campaigns,
    ROUND(SUM(Emails_Sent)     / 1e6, 2)          AS sent_M,
    ROUND(SUM(Revenue_VND)     / 1e9, 2)          AS revenue_B_VND,
    ROUND(AVG("Open_Rate_%"),   2)                AS avg_open_pct,
    ROUND(AVG("Conv_Rate_%"),   2)                AS avg_conv_pct
FROM email_campaigns
GROUP BY Quarter
ORDER BY Quarter;


-- ===========================================================================
-- BQ8 — DELIVERABILITY HEALTH
-- ===========================================================================

SELECT
    Campaign_Type,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Delivery_Rate_%"), 2)              AS avg_delivery_pct,
    ROUND(AVG("Bounce_Rate_%"),   2)              AS avg_bounce_pct,
    ROUND(AVG("Unsub_Rate_%"),    2)              AS avg_unsub_pct,
    ROUND(AVG("Spam_Rate_%"),     4)              AS avg_spam_pct,
    ROUND(SUM(Hard_Bounces) / 1e3, 2)             AS hard_bounces_K,
    ROUND(SUM(Unsubscribes) / 1e3, 2)            AS unsubscribes_K
FROM email_campaigns
GROUP BY Campaign_Type
ORDER BY avg_unsub_pct DESC;


-- ===========================================================================
-- BQ9 — DEVICE & EMAIL CLIENT PERFORMANCE
-- ===========================================================================

-- 9a. By device
SELECT
    Primary_Device,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND
FROM email_campaigns
GROUP BY Primary_Device
ORDER BY avg_conv_pct DESC;

-- 9b. By email client
SELECT
    Top_Email_Client,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(AVG("Bounce_Rate_%"),2)                 AS avg_bounce_pct
FROM email_campaigns
GROUP BY Top_Email_Client
ORDER BY avg_conv_pct DESC;


-- ===========================================================================
-- BQ10 — AUTOMATION TRIGGER EFFECTIVENESS
-- ===========================================================================

SELECT
    Automation_Trigger,
    COUNT(*)                                      AS campaigns,
    ROUND(AVG("Open_Rate_%"),  2)                 AS avg_open_pct,
    ROUND(AVG("CTR_%"),        2)                 AS avg_ctr_pct,
    ROUND(AVG("Conv_Rate_%"),  2)                 AS avg_conv_pct,
    ROUND(SUM(Revenue_VND) / 1e9, 2)              AS revenue_B_VND,
    ROUND(AVG(Revenue_per_Email_VND), 0)          AS avg_rev_per_email
FROM email_campaigns
GROUP BY Automation_Trigger
ORDER BY avg_conv_pct DESC;


-- ===========================================================================
-- EXTRA — TOP 20 CAMPAIGNS BY REVENUE
-- ===========================================================================

SELECT
    Email_ID,
    Campaign_Name,
    Brand,
    Campaign_Type,
    CRM_Stage,
    Target_Segment,
    ROUND(Revenue_VND / 1e9, 3)                   AS revenue_B_VND,
    Revenue_per_Email_VND,
    ROUND("Open_Rate_%", 2)                       AS open_pct,
    ROUND("CTR_%", 2)                             AS ctr_pct,
    ROUND("Conv_Rate_%", 2)                       AS conv_pct,
    Status
FROM email_campaigns
ORDER BY Revenue_VND DESC
LIMIT 20;


-- ===========================================================================
-- EXTRA — HIGH UNSUB RISK CAMPAIGNS
-- ===========================================================================

SELECT
    Campaign_Name,
    Brand,
    Campaign_Type,
    CRM_Stage,
    ROUND("Unsub_Rate_%", 2)                      AS unsub_pct,
    ROUND("Spam_Rate_%",  4)                      AS spam_pct,
    ROUND("Bounce_Rate_%",2)                      AS bounce_pct,
    ROUND("Conv_Rate_%",  2)                      AS conv_pct,
    Status
FROM email_campaigns
WHERE "Unsub_Rate_%"  > 1.0
   OR "Spam_Rate_%"   > 0.1
ORDER BY "Unsub_Rate_%" DESC
LIMIT 20;


-- ===========================================================================
-- EXTRA — CAMPAIGN TYPE × CRM STAGE PIVOT (Conv Rate)
-- ===========================================================================

SELECT
    Campaign_Type,
    ROUND(AVG(CASE WHEN CRM_Stage = 'Lead'        THEN "Conv_Rate_%" END), 2) AS "Lead",
    ROUND(AVG(CASE WHEN CRM_Stage = 'MQL'         THEN "Conv_Rate_%" END), 2) AS "MQL",
    ROUND(AVG(CASE WHEN CRM_Stage = 'SQL'         THEN "Conv_Rate_%" END), 2) AS "SQL",
    ROUND(AVG(CASE WHEN CRM_Stage = 'Opportunity' THEN "Conv_Rate_%" END), 2) AS "Opportunity",
    ROUND(AVG(CASE WHEN CRM_Stage = 'Customer'    THEN "Conv_Rate_%" END), 2) AS "Customer",
    ROUND(AVG(CASE WHEN CRM_Stage = 'At-Risk'     THEN "Conv_Rate_%" END), 2) AS "At-Risk",
    ROUND(AVG(CASE WHEN CRM_Stage = 'Churned'     THEN "Conv_Rate_%" END), 2) AS "Churned",
    ROUND(AVG("Conv_Rate_%"), 2)                                               AS overall_avg
FROM email_campaigns
GROUP BY Campaign_Type
ORDER BY overall_avg DESC;


-- ===========================================================================
-- EXTRA — SEND DAY × HOUR CONV RATE MATRIX
-- ===========================================================================

SELECT
    Send_Day,
    ROUND(AVG(CASE WHEN Send_Hour BETWEEN  6 AND  8 THEN "Conv_Rate_%" END), 2) AS "06-09h",
    ROUND(AVG(CASE WHEN Send_Hour BETWEEN  9 AND 11 THEN "Conv_Rate_%" END), 2) AS "09-12h",
    ROUND(AVG(CASE WHEN Send_Hour BETWEEN 12 AND 14 THEN "Conv_Rate_%" END), 2) AS "12-15h",
    ROUND(AVG(CASE WHEN Send_Hour BETWEEN 15 AND 17 THEN "Conv_Rate_%" END), 2) AS "15-18h",
    ROUND(AVG(CASE WHEN Send_Hour BETWEEN 18 AND 20 THEN "Conv_Rate_%" END), 2) AS "18-21h",
    ROUND(AVG("Conv_Rate_%"), 2)                                                 AS day_avg
FROM email_campaigns
GROUP BY Send_Day
ORDER BY day_avg DESC;
