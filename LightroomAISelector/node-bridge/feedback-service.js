/**
 * Pickit Feedback Service
 * Handles feedback submission to Google Sheets
 */

const { google } = require('googleapis');
const fs = require('fs').promises;
const path = require('path');

class FeedbackService {
    constructor() {
        this.initialized = false;
        this.sheets = null;
        this.spreadsheetId = process.env.FEEDBACK_SHEET_ID || '1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw';
        this.credentialsPath = path.join(__dirname, 'credentials.json');
    }

    /**
     * Initialize Google Sheets API
     */
    async initialize() {
        if (this.initialized) return;

        try {
            // Load credentials
            const credentials = await this.loadCredentials();
            
            // Set up authentication
            const auth = new google.auth.GoogleAuth({
                credentials: credentials,
                scopes: ['https://www.googleapis.com/auth/spreadsheets']
            });

            // Initialize sheets API
            this.sheets = google.sheets({ version: 'v4', auth });
            this.initialized = true;
            
            console.log('FeedbackService initialized successfully');
        } catch (error) {
            console.error('Failed to initialize FeedbackService:', error);
            throw error;
        }
    }

    /**
     * Load Google API credentials
     */
    async loadCredentials() {
        try {
            // Try to load from file
            const credentialsData = await fs.readFile(this.credentialsPath, 'utf8');
            return JSON.parse(credentialsData);
        } catch (error) {
            // Fallback to environment variables
            return {
                type: 'service_account',
                project_id: process.env.GOOGLE_PROJECT_ID,
                private_key_id: process.env.GOOGLE_PRIVATE_KEY_ID,
                private_key: process.env.GOOGLE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                client_email: process.env.GOOGLE_CLIENT_EMAIL,
                client_id: process.env.GOOGLE_CLIENT_ID,
                auth_uri: 'https://accounts.google.com/o/oauth2/auth',
                token_uri: 'https://oauth2.googleapis.com/token',
                auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
                client_x509_cert_url: process.env.GOOGLE_CERT_URL
            };
        }
    }

    /**
     * Submit feedback to Google Sheets
     */
    async submitFeedback(feedbackData) {
        if (!this.initialized) {
            await this.initialize();
        }

        try {
            // Prepare row data
            const values = [[
                feedbackData.submissionId || this.generateSubmissionId(),
                feedbackData.timestamp || new Date().toISOString(),
                feedbackData.pluginVersion || '1.0.0',
                feedbackData.lightroomVersion || '',
                feedbackData.osInfo || '',
                feedbackData.feedbackType || 'general_feedback',
                feedbackData.category || '',
                feedbackData.rating || 0,
                feedbackData.title || '',
                feedbackData.description || '',
                feedbackData.userName || '',
                feedbackData.userEmail || '',
                feedbackData.contactPermission || false,
                feedbackData.screenshotUrl || '',
                feedbackData.deviceInfo || '',
                feedbackData.usageFrequency || '',
                feedbackData.professionalLevel || '',
                'pending', // status
                '', // team_notes
                ''  // response
            ]];

            // Append to sheet
            const response = await this.sheets.spreadsheets.values.append({
                spreadsheetId: this.spreadsheetId,
                range: 'Feedback!A:T',
                valueInputOption: 'USER_ENTERED',
                insertDataOption: 'INSERT_ROWS',
                resource: { values }
            });

            console.log(`Feedback submitted: ${feedbackData.submissionId}`);
            
            // Send notification for critical feedback
            if (feedbackData.feedbackType === 'bug_report' || feedbackData.rating <= 2) {
                await this.sendNotification(feedbackData);
            }

            return {
                success: true,
                submissionId: feedbackData.submissionId,
                updatedRange: response.data.updates.updatedRange
            };
        } catch (error) {
            console.error('Failed to submit feedback:', error);
            throw error;
        }
    }

    /**
     * Check for responses to previous feedback
     */
    async checkResponses(submissionIds) {
        if (!this.initialized) {
            await this.initialize();
        }

        try {
            // Get all feedback data
            const response = await this.sheets.spreadsheets.values.get({
                spreadsheetId: this.spreadsheetId,
                range: 'Feedback!A:T'
            });

            const rows = response.data.values || [];
            const responses = [];

            // Find responses for given submission IDs
            for (let i = 1; i < rows.length; i++) { // Skip header row
                const row = rows[i];
                const submissionId = row[0];
                const status = row[17];
                const teamResponse = row[19];

                if (submissionIds.includes(submissionId) && teamResponse) {
                    responses.push({
                        submissionId,
                        status,
                        response: teamResponse,
                        timestamp: row[1]
                    });
                }
            }

            return responses;
        } catch (error) {
            console.error('Failed to check responses:', error);
            return [];
        }
    }

    /**
     * Get feedback statistics
     */
    async getStatistics() {
        if (!this.initialized) {
            await this.initialize();
        }

        try {
            const response = await this.sheets.spreadsheets.values.get({
                spreadsheetId: this.spreadsheetId,
                range: 'Feedback!A:T'
            });

            const rows = response.data.values || [];
            const stats = {
                total: rows.length - 1, // Exclude header
                byType: {},
                byRating: {},
                byStatus: {},
                averageRating: 0
            };

            let totalRating = 0;
            let ratingCount = 0;

            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                const type = row[5];
                const rating = parseInt(row[7]) || 0;
                const status = row[17];

                // Count by type
                stats.byType[type] = (stats.byType[type] || 0) + 1;

                // Count by rating
                if (rating > 0) {
                    stats.byRating[rating] = (stats.byRating[rating] || 0) + 1;
                    totalRating += rating;
                    ratingCount++;
                }

                // Count by status
                stats.byStatus[status] = (stats.byStatus[status] || 0) + 1;
            }

            // Calculate average rating
            if (ratingCount > 0) {
                stats.averageRating = (totalRating / ratingCount).toFixed(2);
            }

            return stats;
        } catch (error) {
            console.error('Failed to get statistics:', error);
            return null;
        }
    }

    /**
     * Send notification for critical feedback
     */
    async sendNotification(feedbackData) {
        // This would integrate with email service or Slack
        // For now, just log
        console.log(`ALERT: ${feedbackData.feedbackType} - ${feedbackData.title}`);
        
        // You can implement email notification here using nodemailer
        // or Slack notification using webhook
    }

    /**
     * Generate unique submission ID
     */
    generateSubmissionId() {
        const date = new Date();
        const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
        return `FB${dateStr}${random}`;
    }

    /**
     * Create feedback sheet if it doesn't exist
     */
    async createSheetIfNeeded() {
        if (!this.initialized) {
            await this.initialize();
        }

        try {
            // Check if sheet exists
            const sheets = await this.sheets.spreadsheets.get({
                spreadsheetId: this.spreadsheetId
            });

            const feedbackSheet = sheets.data.sheets.find(
                sheet => sheet.properties.title === 'Feedback'
            );

            if (!feedbackSheet) {
                // Create sheet with headers
                await this.sheets.spreadsheets.batchUpdate({
                    spreadsheetId: this.spreadsheetId,
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

                // Add headers
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

                await this.sheets.spreadsheets.values.update({
                    spreadsheetId: this.spreadsheetId,
                    range: 'Feedback!A1:T1',
                    valueInputOption: 'RAW',
                    resource: { values: headers }
                });

                console.log('Feedback sheet created successfully');
            }
        } catch (error) {
            console.error('Failed to create sheet:', error);
        }
    }
}

module.exports = FeedbackService;