#!/usr/bin/env node

/**
 * Pickit Feedback System Setup Script
 * Initializes Google Sheets with proper structure
 */

const { google } = require('googleapis');
const fs = require('fs').promises;
const path = require('path');
const readline = require('readline');

const SPREADSHEET_ID = '1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function setupFeedbackSheet() {
    console.log('🚀 Pickit Feedback System Setup');
    console.log('================================\n');
    
    try {
        // Check for credentials
        const credentialsPath = path.join(__dirname, '..', 'credentials.json');
        let credentials;
        
        try {
            const credentialsData = await fs.readFile(credentialsPath, 'utf8');
            credentials = JSON.parse(credentialsData);
            console.log('✅ Found credentials.json');
        } catch (error) {
            console.log('❌ credentials.json not found');
            console.log('\nPlease follow these steps:');
            console.log('1. Go to Google Cloud Console');
            console.log('2. Create a service account');
            console.log('3. Download the JSON key');
            console.log('4. Save it as node-bridge/credentials.json');
            console.log('\nSee GOOGLE_SHEETS_SETUP.md for detailed instructions.');
            process.exit(1);
        }
        
        // Initialize Google Sheets API
        console.log('\n📊 Connecting to Google Sheets...');
        const auth = new google.auth.GoogleAuth({
            credentials: credentials,
            scopes: ['https://www.googleapis.com/auth/spreadsheets']
        });
        
        const sheets = google.sheets({ version: 'v4', auth });
        
        // Check if we can access the spreadsheet
        try {
            const spreadsheet = await sheets.spreadsheets.get({
                spreadsheetId: SPREADSHEET_ID
            });
            console.log(`✅ Connected to: ${spreadsheet.data.properties.title}`);
        } catch (error) {
            console.log('❌ Cannot access spreadsheet');
            console.log(`\nPlease share the spreadsheet with:`);
            console.log(`📧 ${credentials.client_email}`);
            console.log('\nGrant "Editor" permission and try again.');
            process.exit(1);
        }
        
        // Check if Feedback sheet exists
        const response = await sheets.spreadsheets.get({
            spreadsheetId: SPREADSHEET_ID
        });
        
        const feedbackSheet = response.data.sheets.find(
            sheet => sheet.properties.title === 'Feedback'
        );
        
        if (feedbackSheet) {
            console.log('✅ Feedback sheet already exists');
            
            const overwrite = await question('\nOverwrite existing sheet? (y/n): ');
            if (overwrite.toLowerCase() !== 'y') {
                console.log('Setup cancelled.');
                rl.close();
                return;
            }
        }
        
        // Create or update sheet structure
        console.log('\n📝 Setting up sheet structure...');
        
        // Headers for the feedback sheet
        const headers = [[
            'Submission ID',
            'Timestamp',
            'Plugin Version',
            'Lightroom Version',
            'OS Info',
            'Feedback Type',
            'Category',
            'Rating',
            'Title',
            'Description',
            'User Name',
            'User Email',
            'Contact Permission',
            'Screenshot URL',
            'Device Info',
            'Usage Frequency',
            'Professional Level',
            'Status',
            'Team Notes',
            'Response'
        ]];
        
        // Clear existing data and set headers
        if (feedbackSheet) {
            await sheets.spreadsheets.values.clear({
                spreadsheetId: SPREADSHEET_ID,
                range: 'Feedback!A:T'
            });
        } else {
            // Create new sheet
            await sheets.spreadsheets.batchUpdate({
                spreadsheetId: SPREADSHEET_ID,
                resource: {
                    requests: [{
                        addSheet: {
                            properties: {
                                title: 'Feedback',
                                gridProperties: {
                                    rowCount: 1000,
                                    columnCount: 20
                                }
                            }
                        }
                    }]
                }
            });
        }
        
        // Add headers
        await sheets.spreadsheets.values.update({
            spreadsheetId: SPREADSHEET_ID,
            range: 'Feedback!A1:T1',
            valueInputOption: 'RAW',
            resource: { values: headers }
        });
        
        console.log('✅ Headers added');
        
        // Format the header row
        await sheets.spreadsheets.batchUpdate({
            spreadsheetId: SPREADSHEET_ID,
            resource: {
                requests: [
                    {
                        repeatCell: {
                            range: {
                                sheetId: feedbackSheet ? feedbackSheet.properties.sheetId : 0,
                                startRowIndex: 0,
                                endRowIndex: 1
                            },
                            cell: {
                                userEnteredFormat: {
                                    backgroundColor: {
                                        red: 0.2,
                                        green: 0.2,
                                        blue: 0.2
                                    },
                                    textFormat: {
                                        foregroundColor: {
                                            red: 1,
                                            green: 1,
                                            blue: 1
                                        },
                                        bold: true
                                    }
                                }
                            },
                            fields: 'userEnteredFormat(backgroundColor,textFormat)'
                        }
                    },
                    {
                        updateSheetProperties: {
                            properties: {
                                sheetId: feedbackSheet ? feedbackSheet.properties.sheetId : 0,
                                gridProperties: {
                                    frozenRowCount: 1
                                }
                            },
                            fields: 'gridProperties.frozenRowCount'
                        }
                    }
                ]
            }
        });
        
        console.log('✅ Formatting applied');
        
        // Create Statistics sheet
        console.log('\n📈 Creating Statistics sheet...');
        
        try {
            await sheets.spreadsheets.batchUpdate({
                spreadsheetId: SPREADSHEET_ID,
                resource: {
                    requests: [{
                        addSheet: {
                            properties: {
                                title: 'Statistics',
                                gridProperties: {
                                    rowCount: 100,
                                    columnCount: 10
                                }
                            }
                        }
                    }]
                }
            });
        } catch (error) {
            // Sheet might already exist
        }
        
        // Add statistics formulas
        const statsData = [
            ['Metric', 'Value', 'Last Updated'],
            ['Total Submissions', '=COUNTA(Feedback!A:A)-1', '=NOW()'],
            ['Average Rating', '=IFERROR(AVERAGE(Feedback!H:H), 0)', ''],
            ['Pending Reviews', '=COUNTIF(Feedback!R:R, "pending")', ''],
            ['Completed Reviews', '=COUNTIF(Feedback!R:R, "completed")', ''],
            ['Bug Reports', '=COUNTIF(Feedback!F:F, "bug_report")', ''],
            ['Feature Requests', '=COUNTIF(Feedback!F:F, "feature_request")', ''],
            ['', '', ''],
            ['Rating Distribution', '', ''],
            ['5 Stars', '=COUNTIF(Feedback!H:H, 5)', ''],
            ['4 Stars', '=COUNTIF(Feedback!H:H, 4)', ''],
            ['3 Stars', '=COUNTIF(Feedback!H:H, 3)', ''],
            ['2 Stars', '=COUNTIF(Feedback!H:H, 2)', ''],
            ['1 Star', '=COUNTIF(Feedback!H:H, 1)', '']
        ];
        
        await sheets.spreadsheets.values.update({
            spreadsheetId: SPREADSHEET_ID,
            range: 'Statistics!A1:C14',
            valueInputOption: 'USER_ENTERED',
            resource: { values: statsData }
        });
        
        console.log('✅ Statistics sheet created');
        
        // Add test data
        const addTestData = await question('\nAdd test data? (y/n): ');
        if (addTestData.toLowerCase() === 'y') {
            const testData = [
                [
                    'FB20250120001',
                    new Date().toISOString(),
                    '1.0.0',
                    'Lightroom Classic 12.0',
                    'macOS 14.0',
                    'feature_request',
                    'ui_improvement',
                    5,
                    '測試：建議增加批次導出功能',
                    '希望能夠一次導出多個預設格式，節省時間。',
                    'Test User',
                    'test@example.com',
                    'TRUE',
                    '',
                    'MacBook Pro M1',
                    'daily',
                    'professional',
                    'pending',
                    '',
                    ''
                ]
            ];
            
            await sheets.spreadsheets.values.append({
                spreadsheetId: SPREADSHEET_ID,
                range: 'Feedback!A:T',
                valueInputOption: 'USER_ENTERED',
                insertDataOption: 'INSERT_ROWS',
                resource: { values: testData }
            });
            
            console.log('✅ Test data added');
        }
        
        console.log('\n🎉 Setup Complete!');
        console.log('\nYour feedback system is ready to use.');
        console.log(`\n📊 View your spreadsheet:`);
        console.log(`https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}`);
        
        console.log('\n📝 Next steps:');
        console.log('1. Start the Node.js server: npm start');
        console.log('2. Open Lightroom Classic');
        console.log('3. Go to: 圖庫 → 插件附加功能 → Pickit - 意見回饋');
        console.log('4. Submit feedback!');
        
    } catch (error) {
        console.error('\n❌ Setup failed:', error.message);
        console.error('\nPlease check GOOGLE_SHEETS_SETUP.md for troubleshooting.');
    } finally {
        rl.close();
    }
}

// Run setup
setupFeedbackSheet().catch(console.error);