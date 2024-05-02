// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// scrolling logic for the nav menu
let lastScrollTop = 0;
const navElement = document.getElementById("main_nav");

window.addEventListener("scroll", function () {
  let scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  if (scrollTop > lastScrollTop) {
    // Scrolling down
    navElement.classList.add("-translate-y-80");
    navElement.classList.remove("-translate-y-0");
  } else {
    // Scrolling up
    navElement.classList.remove("-translate-y-80");
    navElement.classList.add("-translate-y-0");
  }
  lastScrollTop = scrollTop;
});

document.addEventListener("DOMContentLoaded", function () {
  // Main nav open/close logic
  const open_mobile_nav = document.getElementById("open_mobile_nav");
  const close_mobile_nav = document.getElementById("close_mobile_nav");
  open_mobile_nav.addEventListener("click", () => {
    const targetElement = document.getElementById("mobile_menu");
    targetElement.classList.add('opacity-100', 'visible');
    targetElement.classList.remove('opacity-0', 'invisible');
  });
  close_mobile_nav.addEventListener("click", () => {
    const targetElement = document.getElementById("mobile_menu");
    targetElement.classList.add('opacity-0', 'invisible');
    targetElement.classList.remove('opacity-100', 'visible');
    targetElement.style.height = null;
  });
});
