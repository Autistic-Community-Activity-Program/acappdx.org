document.addEventListener("DOMContentLoaded", () => {
    const admin_btn = document.getElementById("admin_btn");
    const user_admin = document.getElementById("user_admin");

    admin_btn.addEventListener("click", () => {
        console.debug("click")
        console.debug(user_admin.value)
        if (user_admin.value === "true") {
            user_admin.value = ""
            admin_btn.classList.add("bg-indigo-200");
            admin_btn.classList.remove("bg-indigo-600");
            admin_btn.querySelector('span').classList.add("translate-x-0");
            admin_btn.querySelector('span').classList.remove("translate-x-5");
        } else {
            user_admin.value = "true"
            admin_btn.classList.add("bg-indigo-600");
            admin_btn.classList.remove("bg-indigo-200");
            admin_btn.querySelector('span').classList.add("translate-x-5");
            admin_btn.querySelector('span').classList.remove("translate-x-0");
        }
    })

});
