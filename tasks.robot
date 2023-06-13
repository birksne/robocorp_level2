*** Settings ***
Documentation       Template robot main suite.
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive



*** Tasks ***
Minimal task
    Access webpage
    Folder management
    Loop time
    Archive receipts with ZIP



*** Keywords ***
Access webpage
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Folder management
    ${receipts_exist?}=    Does Directory Exist    ${CURDIR}${/}receipts
    ${screenshots_exist?}=    Does Directory Exist    ${CURDIR}${/}screenshots  
    Run Keyword If    '${receipts_exist?}'=='True'    Remove Directory    ${CURDIR}${/}receipts    recursive=${True}
    Run Keyword If    '${screenshots_exist?}'=='True'    Remove Directory    ${CURDIR}${/}screenshots    recursive=${True}
    Create Directory    ${CURDIR}${/}receipts
    Create Directory    ${CURDIR}${/}screenshots

Loop time
    Download    https://robotsparebinindustries.com/orders.csv    
    @{orders}=    Read table from CSV    ${CURDIR}${/}orders.csv    header=TRUE

    FOR    ${row}    IN   @{orders}
    Fill the form    ${row}
    Get robot preview
    Complete order
    Get receipt and screenshot and merge them   ${row}
    Prepare for next order
    END


*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    
Get robot preview
    Click Button    Preview
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]
    # Exception handling

Complete order
    Click Button    order
    ${checkIfComplete}=    Is Element Visible    //div[@id="receipt"]
    Run Keyword If    '${checkIfComplete}'=='False'   Complete order
    # Saying if we dont see a receipt, click the button until we do. However, this would lead to a infinite loop if something was really wrong.

Prepare for next order
    Click Button    id:order-another
    Click Button    OK

Get receipt and screenshot and merge them
    [Arguments]    ${row}
    ${html_receipt}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    HTML to PDF    ${html_receipt}    ${CURDIR}${/}receipts/receipt_order_${row}[Order number].pdf
    Capture Element Screenshot    //div[@id="robot-preview-image"]     ${CURDIR}${/}screenshots/robot_preview_${row}[Order number].png
    Add Watermark Image To Pdf    ${CURDIR}${/}screenshots/robot_preview_${row}[Order number].png    
    ...    ${CURDIR}${/}receipts/receipt_order_${row}[Order number].pdf
    ...    ${CURDIR}${/}receipts/receipt_order_${row}[Order number].pdf

Archive receipts with ZIP
    Archive Folder With Zip    ${CURDIR}${/}receipts    receipts.zip

    