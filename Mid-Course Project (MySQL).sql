USE mavenfuzzyfactory;


/*Monthly Trends for Gsearch sessions & Orders*/
SELECT MONTH(ws.created_at) month_num,
       COUNT(ws.website_session_id) sessions,
	   COUNT(o.order_id) orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.utm_source='gsearch'
      AND ws.created_at<'2012-11-27'
GROUP BY 1
ORDER BY 1; 
--In general, both sessions and orders have increasing trends in this 8-month period


/*Spliting Out Nonbrand & Brand Campaigns Based on the Previous Query*/
SELECT MONTH(ws.created_at) month_num,
       COUNT(CASE WHEN ws.utm_campaign='nonbrand'THEN ws.website_session_id ELSE NULL END) nonbrand_sessions,
	   COUNT(CASE WHEN ws.utm_campaign='nonbrand' THEN o.order_id ELSE NULL END) nonbrand_orders,
	   COUNT(CASE WHEN ws.utm_campaign='brand' THEN ws.website_session_id ELSE NULL END) brand_sessions,	   
	   COUNT(CASE WHEN ws.utm_campaign='brand' THEN o.order_id ELSE NULL END) brand_orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.utm_source='gsearch'
      AND ws.created_at<'2012-11-27'
GROUP BY 1
ORDER BY 1; 
--Upward trends can be spotted for both nonbrand sessions and brand sessions. And the number of nonbrand sessions are 30 to 40 times more than brand sessions.


/*Spliting Sessions & Orders by Device Type*/
---Based on the result of first query
SELECT MONTH(ws.created_at) month_num,
       COUNT(CASE WHEN ws.device_type='desktop' THEN ws.website_session_id ELSE NULL END) desktop_sessions,
	   COUNT(CASE WHEN ws.device_type='desktop' THEN o.order_id ELSE NULL END) desktop_orders,
	   COUNT(CASE WHEN ws.device_type='mobile' THEN ws.website_session_id ELSE NULL END) mobile_sessions,	   
	   COUNT(CASE WHEN ws.device_type='mobile' THEN o.order_id ELSE NULL END) mobile_orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.utm_source='gsearch'
      AND ws.utm_campaign='nonbrand'
      AND ws.created_at<'2012-11-27'
GROUP BY 1
ORDER BY 1;
--Desktop devices tend to attract two to three times more sessions and orders than mobile devices. Significant increments can be seen for both sessions in November.


/*Monthly Trends for Gsearch & Other Channels*/
---Identify utm Sources
SELECT DISTINCT utm_source,utm_campaign,http_referer
FROM website_sessions
WHERE created_at<'2012-11-27';
--There are 7 types of traffic in total: bsearch brand, gsearch brand, bsearch nonbrand, gsearch nonbrand, bsearch organic, gsearch organic, direct

---Calulate Trends for each Channel
SELECT MONTH(ws.created_at) month_num,
       COUNT(CASE WHEN ws.utm_source='gsearch' THEN ws.website_session_id ELSE NULL END) gsearch_sessions,	   
	   COUNT(CASE WHEN ws.utm_source='gsearch' THEN o.order_id ELSE NULL END) gsearch_orders,
	   COUNT(CASE WHEN ws.utm_source='bsearch' THEN ws.website_session_id ELSE NULL END) bsearch_sessions,
	   COUNT(CASE WHEN ws.utm_source='bsearch' THEN o.order_id ELSE NULL END) bsearch_orders,
	   COUNT(CASE WHEN ws.utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) organic_sessions,
	   COUNT(CASE WHEN ws.utm_source IS NULL AND http_referer IS NOT NULL THEN o.order_id ELSE NULL END) organic_orders,
	   COUNT(CASE WHEN ws.utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) direct_sessions,
	   COUNT(CASE WHEN ws.utm_source IS NULL AND http_referer IS NULL THEN o.order_id ELSE NULL END) direct_orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.created_at<'2012-11-27'
GROUP BY 1
ORDER BY 1;
--Upward trends of sessions & orders can also be seen for organic traffic and direct traffic


/*Calculate Monthly Session to Order Conversion Rates*/
SELECT MONTH(ws.created_at) month_num,
       COUNT(ws.website_session_id) sessions,
	   COUNT(o.order_id) orders,
	   ROUND(COUNT(o.order_id)/COUNT(ws.website_session_id),4) cvr	   	   
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.created_at<'2012-11-27'
GROUP BY 1
ORDER BY 1;
--In general, the session to order conversion rates show an increasing trend in the past 8 months.
--Our website performance has improved by approx. 2%.


/*Estimate Gsearch Lander Test Revenue*/
---Look at the increment of cvr from Jun 19-July 28 (testing period)
SELECT wp.pageview_url,
       COUNT(ws.website_session_id) sessions,
	   COUNT(o.order_id) orders,
	   ROUND(COUNT(o.order_id)/COUNT(ws.website_session_id),4) cvr
FROM website_pageviews wp
JOIN website_sessions ws
ON wp.website_session_id=ws.website_session_id
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
WHERE ws.utm_source='gsearch'
      AND ws.utm_campaign='nonbrand'
      AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
	  AND wp.pageview_url IN ('/home','/lander-1')
GROUP BY 1;
--CVR for /home: 3.18%, CVR for /lander-1: 4.06%.
--In other words, the new landing page receives 0.88% more sessions to order conversion rate

---Find the last '/home' session for gsearch nonbrand
SELECT MAX(wp.website_session_id) max_home_page
FROM website_pageviews wp
JOIN website_sessions ws
ON wp.website_session_id=ws.website_session_id
WHERE wp.created_at BETWEEN '2012-07-28' AND '2012-11-27'
    AND wp.pageview_url='/home'
	AND ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'; 
--The last '/home' session id is 17145

---Calculate the website sessions after the test
SELECT COUNT(website_session_id) sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'; 
--There are 22972 website sessions after the test
--In other words, there are approx. 202 more orders in four months--approx. 50 more orders per month. This suggests that the new landing page does boost revenue effectively


/*Full Conversion Funnel of The Two Pages To Orders*/
---Select all pageviews for relevant sessions
CREATE TEMPORARY TABLE page_view_level 
	 SELECT ws.website_session_id,
            wp.pageview_url,
	        CASE WHEN wp.pageview_url IN ('/home','/lander-1') THEN 1 ELSE 0 END home,
	        CASE WHEN wp.pageview_url='/products' THEN 1 ELSE 0 END products,
	        CASE WHEN wp.pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END mr_fuzzy,
	        CASE WHEN wp.pageview_url='/cart' THEN 1 ELSE 0 END cart,
	        CASE WHEN wp.pageview_url='/shipping' THEN 1 ELSE 0 END shipping,
	        CASE WHEN wp.pageview_url='/billing' THEN 1 ELSE 0 END billing,
	        CASE WHEN wp.pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END tyfyo
     FROM website_sessions ws
     LEFT JOIN website_pageviews wp
     ON ws.website_session_id=wp.website_session_id
     WHERE wp.created_at BETWEEN '2012-06-19' AND '2012-07-28'
           AND ws.utm_source='gsearch'
	       AND ws.utm_campaign='nonbrand';
     

---Create session-level conversion funnel review
CREATE TEMPORARY TABLE sessions_made_it
	 SELECT website_session_id,
		    MAX(home) h_made_it,
	        MAX(products) p_made_it,
	        MAX(mr_fuzzy) mf_made_it,
	        MAX(cart) cart_made_it,
	        MAX(shipping) s_made_it,
	        MAX(billing) b_made_it,
	        MAX(tyfyo) t_made_it
     FROM page_view_level
     GROUP BY 1;

---Aggregate the data to assess funnel performance
CREATE TEMPORARY TABLE funnel_counts
	  SELECT pvl.pageview_url landing_page,
             COUNT(sml.website_session_id) sessions,
	         COUNT(CASE WHEN sml.p_made_it=1 THEN sml.website_session_id ELSE NULL END) to_products,
	         COUNT(CASE WHEN sml.mf_made_it=1 THEN sml.website_session_id ELSE NULL END) to_mrfuzzy,
	         COUNT(CASE WHEN sml.cart_made_it=1 THEN sml.website_session_id ELSE NULL END) to_cart,
	         COUNT(CASE WHEN sml.s_made_it=1 THEN sml.website_session_id ELSE NULL END) to_shipping,
	         COUNT(CASE WHEN sml.b_made_it=1 THEN sml.website_session_id ELSE NULL END) to_billing,
	         COUNT(CASE WHEN sml.t_made_it=1 THEN sml.website_session_id ELSE NULL END) to_thankyou
       FROM sessions_made_it sml
	   LEFT JOIN page_view_level pvl
	   ON pvl.website_session_id=sml.website_session_id
	   WHERE pvl.pageview_url IN ('/home','/lander-1')
	   GROUP BY 1;

SELECT landing_page,
       ROUND(to_products/sessions,4) lander_click_rt,
	   ROUND(to_mrfuzzy/to_products,4) product_click_rt,
	   ROUND(to_cart/to_mrfuzzy,4) mrfuzzy_click_rt,
	   ROUND(to_shipping/to_cart,4) cart_click_rt,
	   ROUND(to_billing/to_shipping,4) shipping_click_rt,
	   ROUND(to_thankyou/to_billing,4) billing_click_rt
FROM funnel_counts;	


/*Quantify Billing Page Test Impact*/
---Calculate Revenue per Billing Page Session
CREATE TEMPORARY TABLE page_view_level 
	 SELECT ws.website_session_id,
            wp.pageview_url,
	        CASE WHEN wp.pageview_url='/billing' OR wp.pageview_url='/billing-2' THEN 1 ELSE 0 END billing
     FROM website_sessions ws
     LEFT JOIN website_pageviews wp
     ON ws.website_session_id=wp.website_session_id
     WHERE wp.created_at BETWEEN '2012-09-10' AND '2012-11-10';           

	 
CREATE TEMPORARY TABLE billing_made_it 
	SELECT website_session_id,
           MAX(billing) b_made_it
    FROM page_view_level
    GROUP BY 1;
	
CREATE TEMPORARY TABLE billing_revenue 
    SELECT pvl.pageview_url billing_page,  
           COUNT(CASE WHEN bmi.b_made_it=1 THEN bmi.website_session_id ELSE NULL END) billing_sessions,
	       SUM(o.price_usd) price    
    FROM billing_made_it bmi
    LEFT JOIN page_view_level pvl
    ON pvl.website_session_id=bmi.website_session_id
    LEFT JOIN orders o
    ON bmi.website_session_id=o.website_session_id
    LEFT JOIN order_item_refunds oir
    ON o.order_id=oir.order_id
    WHERE pvl.pageview_url IN('/billing','/billing-2')
    GROUP BY 1;
	
SELECT billing_page,
       ROUND(price/billing_sessions,2) revenue_per_billing_sessions
FROM billing_revenue;

---Calcualte Number of Billing Page Sessions In the Past Month
SELECT COUNT(website_session_id) billing_sessions_past_month
FROM website_pageviews 
WHERE created_at BETWEEN '2012-10-27' AND '2012-11-27'
	  AND pageview_url IN ('/billing','/billing-2');
--Revenue for the old billing page: $22.83, Revenue for the new billing page: $31.34, Web sessions in the past month: 1193
--The new billing page brings $10152.43 more in revenue