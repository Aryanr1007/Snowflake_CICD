CREATE OR REPLACE PROCEDURE "PACKING_DASHBOARD"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN
INSERT OVERWRITE INTO SCA.XFRM.TBL_LDC_PACKING_DASHBOARD
SELECT 
    ITCCB.BRAND_ID AS "Brand ID",
    CASE
        WHEN ITCCB.BRAND_NAME = ''J.Crew Factory'' THEN ''Factory''
        ELSE ITCCB.BRAND_NAME
    END AS "Brand Name",
    CASE
        WHEN ITCCB.DISPLAY_BRAND = ''J.Crew Factory - 8'' THEN ''Factory - 8''
        ELSE ITCCB.DISPLAY_BRAND
    END AS "Display Name",
    CASE
        WHEN BRAND_NAME = ''J.Crew'' THEN 1
        WHEN BRAND_NAME = ''J.Crew Factory'' THEN 2
        WHEN BRAND_NAME = ''Madewell'' THEN 3
        ELSE 4
    END AS "Brand Sort",
    ITCCB.CHANNEL AS "Channel",
    ITCCB.CLIENT AS "Client",
    OL.INVENTORY_TYPE_ID AS "Inventory Type ID",
    OL.ORDER_TYPE AS "Order Type",
    OL.ORIGINAL_ORDER_ID AS "Original Order ID",
    OL.ORDER_LINE_ID AS "Order Line ID",
    OL.STATUS AS "Order Line Status",
    CASE
        WHEN OH.STATUS >= 7200 AND OH.STATUS < 8000 THEN ''Yes''
        ELSE ''No''
    END AS "Packed Not Shipped Flag",
    OH.OLPN_ID AS "OLPN ID",
    OH.STATUS AS "OLPN Status ID",
    POS.OLPN_STATUS_DESCRIPTION AS "OLPN Status",
    OL.PACKED_QUANTITY AS "Packed Quantity",
    CASE
        WHEN TD.WORKING_LOCATION_ID ILIKE ''%AUTO%'' THEN ''Automation''
        ELSE ''Manual''
    END AS "Automation Flag",
    //TD.CREATED_BY AS "User ID",
    TD.UPDATED_BY AS "User ID",
    TD.WORKING_LOCATION_ID AS "Working Location ID",
    OH.CURRENT_LOCATION_ID AS "Current Location ID",
    OL.ALLOCATION_SOURCE_ID AS "Allocation Source ID",
    MIN(CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_START_TIME)) AS timestamp_ntz(9))) AS "Task Start Date Time",
    MAX(CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_END_TIME)) AS timestamp_ntz(9))) AS "Task End Date Time",
    CAST(CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_END_TIME) AS timestamp_ntz(9)) AS "Actual End Time",
    CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_END_TIME)) AS timestamp_ntz(9)) AS "Worked Date Actual End Time",
    SCA.XFRM.UDF_SCA_WORKED_SHIFT(CAST(TD.ACTUAL_END_TIME AS timestamp_ntz(9))) AS "Work Shift Actual End Time",
    CAST(CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_START_TIME) AS timestamp_ntz(9)) AS "Actual Start Time",
    CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TD.ACTUAL_START_TIME)) AS timestamp_ntz(9)) AS "Worked Date Actual Start Time",
    SCA.XFRM.UDF_SCA_WORKED_SHIFT(CAST(TD.ACTUAL_START_TIME AS timestamp_ntz(9))) AS  "Work Shift Actual Start Time",
    CAST(CONVERT_TIMEZONE(''America/New_York'', TD.UPDATED_TIMESTAMP) AS timestamp_ntz(9)) AS "Task Detail Updated Timestamp",
    DATE(CAST(CONVERT_TIMEZONE(''America/New_York'', TD.UPDATED_TIMESTAMP) AS timestamp_ntz(9))) AS "Task Detail Updated Date",
    HOUR(CAST(CONVERT_TIMEZONE(''America/New_York'', TD.UPDATED_TIMESTAMP) AS timestamp_ntz(9))) AS "Task Detail Updated Hour",
    -- TO_CHAR(CONVERT_TIMEZONE(''America/New_York'', TD.UPDATED_TIMESTAMP), ''HH12 AM'') AS "Task Detail Updated Hour",
    CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TD.UPDATED_TIMESTAMP)) AS timestamp_ntz(9)) AS "Worked Date Task Detail Updated Timestamp",
    SCA.XFRM.UDF_SCA_WORKED_SHIFT(CAST(TD.UPDATED_TIMESTAMP AS timestamp_ntz(9))) AS "Work Shift Task Detail Updated Timestamp",
    CAST(CONVERT_TIMEZONE(''America/New_York'', TH.CREATED_TIMESTAMP) AS timestamp_ntz(9)) AS "Task Header Created Timestamp",
    CAST(DATEADD(hour, -3, CONVERT_TIMEZONE(''America/New_York'', TH.CREATED_TIMESTAMP)) AS timestamp_ntz(9)) AS "Worked Date Task Header Created Timestamp",
    SCA.XFRM.UDF_SCA_WORKED_SHIFT(CAST(TD.CREATED_TIMESTAMP AS timestamp_ntz(9)))  AS "Work Shift Task Header Created Timestamp",
    OH.SERVICE_LEVEL_ID AS "Service Level ID",
    OH.EXTERNAL_MANIFEST_ID AS "External Manifest ID",
    OH.EXT_TRAILER_NUMBER AS "External Trailer Number",
    OH.SHIPMENT_ID AS "Shipment ID",
    OH.TRACKING_NUMBER AS "Tracking Number",
    OH.PALLET_ID AS "Pallet ID",
    OH.REFERENCE_LPN_ID AS "Reference LPN ID",
    OH.MODE_ID AS "Mode ID",
    OH.STATIC_ROUTE_ID AS "Static Route ID",
    CASE
        -- WHEN OH.EXT_LASTPACKEXCEPTION  IS  NOT NULL OR  OH.EXT_PACK_EXCEPTION_CODE IS NOT NULL THEN ''Yes''
        WHEN LENGTH (OH.EXT_LASTPACKEXCEPTION)  > 1 OR  LENGTH(OH.EXT_PACK_EXCEPTION_CODE) > 1 THEN ''Yes''
        ELSE ''No''
    END AS "Exception Flag",
    IFNULL(OH.EXT_LASTPACKEXCEPTION,  OH.EXT_PACK_EXCEPTION_CODE) AS "Exception Reason",
    CASE
        WHEN OH.EXT_LASTPACKEXCEPTION IS NOT NULL THEN ''Pack Station''
        WHEN OH.EXT_PACK_EXCEPTION_CODE IS NOT NULL THEN ''Auto Bagger''
        ELSE ''Not An Exception''
    END AS "Exception Location",
    OD.OLPN_DETAIL_ID AS "OLPN Detail ID",
    OD.ITEM_ID AS "Item ID",
    OH."OLPN Updated Timestamp",
    CAST(CONVERT_TIMEZONE(''America/New_York'', OD.CREATED_TIMESTAMP) AS TIMESTAMP_NTZ(9)) AS "OLPN Detail Created Timestamp",
    OL."Delivery Start Timestamp" AS "Delivery Start Date Timestamp",
    TH.TASK_ID AS "Task ID",
    TD.TASK_DETAIL_ID AS "Task Detail ID",
    TH.TRANSACTION_TYPE_ID as "Transaction Type ID",
    TH.STATUS AS "Task Status",
    THS.DESCRIPTION AS "Task Status Description",
    TDS.DESCRIPTION AS "Task Detail Status Description",
    TH.DESCRIPTION AS "Task Description",
    TH.TRANSACTION_ID AS "Transaction ID",
    OD.SHORTED_QUANTITY AS "Shorted Quantity",
    DORPS.ORDER_PLANNING_RUN_ID AS "Wave Set",
    DORPS."Wave Description", 
    DORPS."Wave Status", 
    POS.OLPN_STATUS_DESCRIPTION AS "OLPN Header Status",
    PODS.OLPN_DETAIL_STATUS_DESCRIPTION as "OLPN Detail Status",
    CASE 
        WHEN L.OB_MANUAL_SORTER_ID = ''CCHOME'' THEN ''Yes''
        WHEN TD.SOURCE_CONTAINER_TYPE_ID = ''LOCATION'' 
             AND TD.SOURCE_CONTAINER_ID ILIKE ''CC%'' THEN ''Yes''   -- creted a fallback value as PPK_OB_SORT_LOCN_ASSIGNMENT doesn''t have data for july, aug, sep(maybe)
        ELSE ''No''
    END AS "Control Clerk Flag",
    TD.SOURCE_CONTAINER_TYPE_ID AS "Source Container Type ID",
    TD.SOURCE_CONTAINER_ID AS "Source Container ID",
    OH.EXT_PUTWALL AS "Putwall",
    OH.EXT_CUBBY AS "Cubby",
    CASE 
        WHEN OH.EXT_PUTWALL LIKE ''%POD%'' THEN ''Online LP''
        WHEN OH.EXT_PUTWALL LIKE ''%FRAME%'' THEN ''Offline LP''
        WHEN OH.EXT_PUTWALL LIKE ''%SORT%'' THEN ''Kindred''
        ELSE ''Unknown''
    END AS "Sort Type"
FROM
    MAWM.MAWM_DEFAULT_PICKPACK.TSK_TASK_DETAIL TD
    INNER JOIN SCA.XFRM.LKP_INVENTORYTYPE_CHANNEL_CLIENT_BRAND ITCCB
        ON TD.ALLOCATED_INVENTORY_TYPE_ID = ITCCB.INVENTORY_TYPE_ID AND ITCCB.FACILITY_ID = ''LDC''
    INNER JOIN SCA.XFRM.OPRS DORPS
    ON TD.GENERATION_NUMBER_ID = DORPS.ORDER_PLANNING_RUN_ID
    AND DORPS._FIVETRAN_DELETED = FALSE 
    JOIN MAWM.MAWM_DEFAULT_PICKPACK.TSK_TASK TH
        ON TD.TASK_ID = TH.TASK_ID
        AND TH._FIVETRAN_DELETED = FALSE
        AND TD._FIVETRAN_DELETED = FALSE
        AND TH.ORG_ID = ''JCREW-LDC''
        AND TD.ORG_ID = ''JCREW-LDC''
        AND TH.TRANSACTION_TYPE_ID = ''Pack''
    LEFT JOIN SCA.XFRM.ORD_LINE OL
    ON OL.ORIGINAL_ORDER_ID = TD.ORIGINAL_ORDER_ID 
    AND OL.ORDER_LINE_ID = TD.ORDER_LINE_ID 
    AND OL._FIVETRAN_DELETED = FALSE
    LEFT JOIN MAWM.MAWM_DEFAULT_PICKPACK.TSK_TASK_STATUS THS 
        ON THS.TASK_STATUS_ID = TH.STATUS
        AND THS._FIVETRAN_DELETED = FALSE
    LEFT JOIN MAWM.MAWM_DEFAULT_PICKPACK.TSK_TASK_DETAIL_STATUS TDS 
        ON TDS.TASK_DETAIL_STATUS_ID = TD.STATUS
        AND TDS._FIVETRAN_DELETED = FALSE
    LEFT JOIN SCA.XFRM.OLPN_HEAD OH
        ON TD.OLPN_ID = OH.OLPN_ID
        AND OH._FIVETRAN_DELETED = FALSE
         -- AND OH.STATUS BETWEEN ''7199'' AND ''9000'' 
    LEFT JOIN SCA.XFRM.OLPN_STATUS POS
        ON OH.STATUS = POS.OLPN_STATUS_ID
        AND POS._FIVETRAN_DELETED = FALSE
    LEFT JOIN SCA.XFRM.OLPN_DETAIL OD ON
    OH.OLPN_ID = OD.OLPN_ID
        AND TD.ORDER_LINE_ID = OD.ORDER_LINE_ID
        AND OD._FIVETRAN_DELETED = FALSE
    LEFT JOIN SCA.XFRM.OLPN_DETAIL_STATUS PODS ON 
    OD.STATUS = PODS.OLPN_DETAIL_STATUS_ID
    AND PODS._FIVETRAN_DELETED = FALSE
    LEFT JOIN (SELECT DISTINCT L.OLPN_ID, L.OB_MANUAL_SORTER_ID
                FROM MAWM.MAWM_DEFAULT_PICKPACK.PPK_OB_SORT_LOCN_ASSIGNMENT L   -- left out fivetran deleted flag on purpose
                WHERE L.FACILITY_ID = ''LDC'') L ON
    TD.OLPN_ID = L.OLPN_ID 
WHERE
    TD.WORKING_CONTAINER_TYPE_ID = ''OLPN''
    --AND TO_DATE(TD.UPDATED_TIMESTAMP) >= CURRENT_DATE - 15
    -- AND TH.TRANSACTION_ID ILIKE ''%Pack from Tote%''
GROUP BY ALL;
END;
';