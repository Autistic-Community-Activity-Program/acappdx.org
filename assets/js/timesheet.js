import { startOfWeek, format, addDays, getDay } from 'date-fns';

function debounce(func, wait) {
    let timeout;
    return function (...args) {
        const context = this;
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(context, args), wait);
    };
}

const handleDateChange = debounce(function (event) {
    if (event.target.value) {
        const form = document.querySelector("#timesheet");
        const formElements = form.elements;

        const dateParts = event.target.value.split("-");
        const selectedDate = new Date(dateParts[0], dateParts[1] - 1, dateParts[2]);

        // Check if selected date is already a Sunday
        let weekStart;
        if (getDay(selectedDate) === 0) { // 0 is Sunday
            weekStart = selectedDate;
        } else {
            weekStart = startOfWeek(selectedDate, { weekStartsOn: 0 });
            showNotification('Defaulted to Sunday: ' + format(weekStart, 'EEE, MM/dd/yy'));
            event.target.value = format(weekStart, 'yyyy-MM-dd');
        }
        // Loop over the IDs from 0 to 6 and update related fields for each entry
        for (let i = 0; i <= 6; i++) {
            const date = addDays(weekStart, i);
            document.getElementById(`timesheet_entries_${i}_label`).textContent = `${format(date, 'EEE, MM/dd/yy')}`;
            document.getElementById(`timesheet_entries_${i}_hours`).value = 0.0;
            document.getElementById(`timesheet_entries_${i}_day`).value = format(date, 'yyyy-MM-dd');
        }
    }
}, 700);

function showNotification(message) {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.style.display = 'block';
    setTimeout(() => {
        notification.style.display = 'none';
    }, 4000); // Hide the notification after 4 seconds
}

document.addEventListener("DOMContentLoaded", function () {
    const week_starting = document.getElementById("timesheet_week_starting");
    week_starting.addEventListener('change', handleDateChange);
});
