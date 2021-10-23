import TiReminders from 'ti.reminders';

// IMPORTANT: Remember to add the "NSRemindersUsageDescription" to your tiapp.xml <ios> plist section first

const window = Ti.UI.createWindow();
window.addEventListener('open', authorize);
window.open();

async function authorize() {
    const success = await TiReminders.requestRemindersPermissions();
    if (!success) {
        alert('No permissions!');
    }

    // Get all reminders
    let reminders = await TiReminders.fetchReminders();
    console.warn(reminders);

    // Update first reminder (available properties: completed, title, completionDate & priority)
    await TiReminders.updateReminder(reminders[0].identifier, {
        completed: true,
        title: `${reminders[0].title} (new)`
    });

    // Delete first reminder
    await TiReminders.removeReminder(reminders[0].identifier);

    // Re-fetch reminders
    reminders = await TiReminders.fetchReminders();
    console.warn(reminders);
}
