Map<String, String> get enLang => {
  "Lang:Key":"en",
  "week 1":"Mon",
  "week 2":"Tues",
  "week 3":"Wed",
  "week 4":"Thur",
  "week 5":"Fri",
  "week 6":"Sat",
  "week 7":"Sun",

  // SmsBot App
  "App:Title":"SMS Forward",
  "App:Add":"Add",
  "App:Save":"Save",
  "App:Cancel":"Cancel",
  "App:Delete":"Delete",
  "App:Enabled":"Enabled",
  "App:Listening":"Listening",
  "App:Paused":"Paused",
  "App:Listening tip":"Notification bar stays on, keeps listening and forwarding after app exit",
  "App:Paused tip":"Enable to keep listening after app exit (notification permission required)",
  "App:Need sms permission":"SMS permission required for listening",
  "App:Forward tip":"After enabling, SMS and missed calls are forwarded to API or email; grant SMS and phone permissions. If sender/content filter is set, only matching ones are forwarded.",
  "App:No API config":"No API config",
  "App:Add API hint":"Tap \"Add API\" below to configure the SMS receiving endpoint",
  "App:API config":"API config",
  "App:Add API":"Add API",
  "App:Add Email":"Add Email",
  "App:No email config":"No email config",
  "App:Add email hint":"Tap \"Add\" and select \"Add Email\"",
  "App:Email config":"Email config",
  "App:Edit API":"Edit API",
  "App:Edit Email":"Edit Email",
  "App:Add Email title":"Add Email",
  "App:Edit Email title":"Edit Email",
  "App:Add API title":"Add API",
  "App:Edit API title":"Edit API",
  "App:Name":"Name",
  "App:Name hint":"e.g. Personal Email",
  "App:Enter name":"Please enter name",
  "App:SMTP server":"SMTP Server",
  "App:SMTP server hint":"smtp.gmail.com",
  "App:Enter SMTP":"Please enter SMTP server",
  "App:Port":"Port",
  "App:Enter port":"Please enter port",
  "App:Invalid port":"Invalid port",
  "App:SSL hint":"465 checked, 587 unchecked",
  "App:SMTP user optional":"SMTP username (optional)",
  "App:SMTP pass optional":"SMTP password (optional)",
  "App:Gmail app password":"Use app-specific password for Gmail",
  "App:From email":"From email",
  "App:From email hint":"from@example.com",
  "App:Enter from email":"Please enter from email",
  "App:To emails":"To emails",
  "App:To emails hint":"Separate multiple with comma",
  "App:Enter to emails":"Please enter to emails",
  "App:Sender filter":"Sender filter",
  "App:Empty filter":"Leave empty for no filter",
  "App:Body filter":"Content filter",
  "App:Delete config":"Delete config",
  "App:Delete email confirm":"Delete this email config?",
  "App:URL":"URL",
  "App:URL hint":"https://api.example.com/sms",
  "App:Enter URL":"Please enter URL",
  "App:Invalid URL":"Please enter a valid URL",
  "App:Method":"Request method",
  "App:Headers count":"Headers (@count)",
  "App:Add header":"Add header",
  "App:Body template":"Request body template (optional)",
  "App:Body template hint":"Placeholders: {{sender}} {{body}} {{date}}",
  "App:Sender filter API":"Only forward numbers containing this, leave empty for no filter",
  "App:Body filter API":"Only forward SMS containing this, leave empty for no filter",
  "App:Enabled subtitle":"Disabled configs will not forward",
  "App:Delete API confirm":"Delete this API config?",
  "App:Logs title":"Forward Logs",
  "App:Clear logs":"Clear logs",
  "App:Clear logs confirm":"Clear all forward logs?",
  "App:Clear":"Clear",
  "App:No logs":"No forward records",
  "App:No logs hint":"Forwarded SMS will appear here",
  "App:Retry":"Retry",
  "App:Delete record":"Delete record",
  "App:Delete record confirm":"Delete this forward record?",
  "App:Retry success":"Forwarded again",
  "App:Retry fail":"API config not found",
  "App:Today":"Today",
  "App:Tip title":"Buy me a coffee",
  "App:Tip desc":"If this app helps you, a small tip would mean a lot!",
  "App:Tip thanks":"Thank you for your support!",
  "App:Tip unavailable":"Tip not available right now",
  "SmsForward:NotForwarded":"Not forwarded",

  // Channel presets
  "App:Add Channel":"Add Chat Platform",
  "App:Add Channel subtitle":"Telegram, Feishu, DingTalk and more",
  "App:Add API subtitle":"Custom HTTP API",
  "App:Add Email subtitle":"SMTP email forwarding",
  "App:Channel preset":"Select Platform",
  "App:Channel preset hint":"Quickly configure forwarding for popular chat apps without manually filling in URLs and request bodies",
  "App:Channel filter":"Filters (optional)",
  "App:Channel guide title":"How to get credentials?",
  "App:Webhook URL":"Webhook URL",
  "App:Enter webhook":"Please enter Webhook URL",

  // Telegram
  "App:Channel desc telegram":"Create a Telegram Bot and enter Bot Token + Chat ID",
  "App:Telegram bot token":"Bot Token",
  "App:Enter bot token":"Please enter Bot Token",
  "App:Telegram chat id":"Chat ID",
  "App:Enter chat id":"Please enter Chat ID",
  "App:Telegram chat id tip":"Get your Chat ID by messaging @userinfobot. Group/channel IDs usually start with -100",
  "App:Channel guide telegram":"""1. Search @BotFather on Telegram, send /newbot to create a bot
2. Follow the prompts — BotFather will give you a Bot Token (e.g. 110201543:AAH...)
3. Add the bot to your target chat or channel
4. Message @userinfobot with /start to get your Chat ID
   • Private chat ID is a positive integer
   • Group/channel IDs start with -100""",

  // Feishu
  "App:Channel desc feishu":"Create a custom bot in a Feishu group and get the Webhook URL",
  "App:Channel guide feishu":"""1. Open a Feishu group → top-right ··· → Settings → Bots
2. Tap "Add Bot" → "Custom Bot"
3. Set a name and description, tap "Add"
4. Copy the Webhook URL and paste it here""",

  // DingTalk
  "App:Channel desc dingtalk":"Create a custom robot in a DingTalk group using keyword security",
  "App:Dingtalk keyword tip":"Note: Only keyword verification is supported. Add a keyword (e.g. 'SMS') in DingTalk robot settings. Every forwarded message must contain that keyword to be accepted",
  "App:Channel guide dingtalk":"""1. Open a DingTalk group → top-right ··· → Smart Group Assistant → Add Robot
2. Choose "Custom" robot and tap "Add"
3. Under security settings, select "Keywords" and add a word (e.g. 'SMS')
4. Copy the Webhook URL and paste it here
Note: Messages must contain the keyword you set, otherwise they will be rejected""",

  // WeCom
  "App:Channel desc wecom":"Create a group bot in WeCom and get the Webhook URL",
  "App:Channel guide wecom":"""1. Open a WeCom group → top-right ··· → Add Group Bot
2. Tap "Create a new bot", set a name
3. Copy the Webhook URL at the bottom and paste it here""",

  // Slack
  "App:Channel desc slack":"Receive messages via Incoming Webhooks",
  "App:Channel guide slack":"""1. Go to https://api.slack.com/apps → "Create New App"
2. Choose "From scratch", set app name and select workspace
3. Go to "Incoming Webhooks" → enable → "Add New Webhook to Workspace"
4. Select target channel and click "Allow"
5. Copy the generated Webhook URL and paste it here""",
};
