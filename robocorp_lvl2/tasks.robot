*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.
...                Author: www.github.com/joergschultzelutter

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           OperatingSystem


*** Variables ***
${ORDER_URL}         https://robotsparebinindustries.com/#/robot-order

${IMAGE_FOLDER}      ${CURDIR}${/}image_files
${PDF_FOLDER}        ${CURDIR}${/}pdf_files
${OUTPUT_FOLDER}     ${CURDIR}${/}output

${ORDERS_FILE}       ${CURDIR}${/}orders.csv
${ZIP_FILE}          ${OUTPUT_FOLDER}${/}pdf_archive.zip
${CSV_URL}           https://robotsparebinindustries.com/orders.csv

*** Test Cases ***
Order Robots from RobotSpareBin Industries Inc
    Open Robot Order Website

    ${ORDERS}=       Get Orders
    FOR    ${ORDER}    IN    @{ORDERS}
        Close Annoying Modal
        Fill Order Form           ${ORDER}
        Wait Until Keyword Succeeds     10x     2s    Preview Robot
        Wait Until Keyword Succeeds     10x     2s    Submit Order
        ${ORDER_ID}    ${IMG_FILENAME}=    Take Screenshot of Robot
        ${PDF_FILENAME}=                Store Receipt as PDF File    ORDER_NUMBER=${ORDER_ID}
        Embed Robot Screenshot to Receipt PDF File     IMG_FILE=${IMG_FILENAME}    PDF_FILE=${PDF_FILENAME}
        Go to Order Another Robot
    END
    Create ZIP File of Receipts

    Log Out And Close Browser


*** Keywords ***
Open Robot Order Website
    Open Available Browser     ${ORDER_URL}

Directory Cleanup
    Log To Console      Cleaning up content from previous test runs

    Create Directory    ${OUTPUT_FOLDER}
    Create Directory    ${IMAGE_FOLDER}
    Create Directory    ${PDF_FOLDER}

    Empty Directory     ${IMAGE_FOLDER}
    Empty Directory     ${PDF_FOLDER}
    Empty Directory     ${OUTPUT_FOLDER}

Get Orders
    Download    url=${CSV_URL}         target_file=${ORDERS_FILE}    overwrite=True
    ${TABLE}=    Read Table from CSV    path=${ORDERS_FILE}
    [Return]    ${TABLE}

Close Annoying Modal
    Set Local Variable              ${BTN_YES}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${BTN_YES}

Fill Order Form
    [Arguments]     ${ORDER_ROW}

    Set Local Variable    ${ORDER_NO}   ${ORDER_ROW}[Order number]
    Set Local Variable    ${HEAD}       ${ORDER_ROW}[Head]
    Set Local Variable    ${BODY}       ${ORDER_ROW}[Body]
    Set Local Variable    ${LEGS}       ${ORDER_ROW}[Legs]
    Set Local Variable    ${ADDRESS}    ${ORDER_ROW}[Address]

    Set Local Variable      ${INPUT_HEAD}       //*[@id="head"]
    Set Local Variable      ${INPUT_BODY}       body
    Set Local Variable      ${INPUT_LEGS}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${INPUT_ADDRESS}    //*[@id="address"]
    Set Local Variable      ${BTN_PREVIEW}      //*[@id="preview"]
    Set Local Variable      ${BTN_ORDER}        //*[@id="order"]
    Set Local Variable      ${IMG_PREVIEW}      //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${INPUT_HEAD}
    Wait Until Element Is Enabled   ${INPUT_HEAD}
    Select From List By Value       ${INPUT_HEAD}           ${HEAD}
    Wait Until Element Is Enabled   ${INPUT_BODY}
    Select Radio Button             ${INPUT_BODY}           ${BODY}
    Wait Until Element Is Enabled   ${INPUT_LEGS}
    Input Text                      ${INPUT_LEGS}           ${LEGS}
    Wait Until Element Is Enabled   ${INPUT_ADDRESS}
    Input Text                      ${INPUT_ADDRESS}        ${ADDRESS}

Preview Robot
    Set Local Variable              ${BTN_PREVIEW}      //*[@id="preview"]
    Set Local Variable              ${IMG_PREVIEW}      //*[@id="robot-preview-image"]
    Click Button                    ${BTN_PREVIEW}
    Wait Until Element Is Visible   ${IMG_PREVIEW}

Submit Order
    Set Local Variable              ${BTN_ORDER}        //*[@id="order"]
    Set Local Variable              ${LBL_RECEIPT}      //*[@id="receipt"]
    Click Button                    ${BTN_ORDER}
    Page Should Contain Element     ${LBL_RECEIPT}

Take Screenshot of Robot
    Set Local Variable      ${LBL_ORDER_ID}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${IMG_ROBOT}        //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${IMG_ROBOT}
    Wait Until Element Is Visible   ${LBL_ORDER_ID} 

    ${ORDER_ID}=                     Get Text            //*[@id="receipt"]/p[1]

    Set Local Variable              ${FULLY_QUALIFIED_IMG_FILENAME}    ${IMAGE_FOLDER}${/}${ORDER_ID}.png

    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${FULLY_QUALIFIED_IMG_FILENAME}
    Capture Element Screenshot      ${IMG_ROBOT}    ${FULLY_QUALIFIED_IMG_FILENAME}
    
    [Return]    ${ORDER_ID}  ${FULLY_QUALIFIED_IMG_FILENAME}

Go to Order Another Robot
    Set Local Variable      ${BTN_ORDER_ANOTHER_ROBOT}      //*[@id="order-another"]
    Click Button            ${BTN_ORDER_ANOTHER_ROBOT}

Log Out And Close Browser
    Close Browser

Create ZIP File of Receipts
    Archive Folder With ZIP     ${PDF_FOLDER}  ${ZIP_FILE}   recursive=True  include=*.pdf

Store Receipt as PDF File
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${ORDER_RECEIPT_HTML}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${FULLY_QUALIFIED_PDF_FILENAME}    ${PDF_FOLDER}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${ORDER_RECEIPT_HTML}   output_path=${FULLY_QUALIFIED_PDF_FILENAME}

    [Return]    ${FULLY_QUALIFIED_PDF_FILENAME}

Embed Robot Screenshot to Receipt PDF File
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}

    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF        ${PDF_FILE}

    @{FILES_TO_ADD}=    Create List     ${IMG_FILE}:x=0,y=0

    Add Files To PDF    ${FILES_TO_ADD}    ${PDF_FILE}     ${True}

    Close PDF           ${PDF_FILE}

