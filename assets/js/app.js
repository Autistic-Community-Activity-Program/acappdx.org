// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
import { themeChange } from 'theme-change'

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


themeChange()
window.onload = () => {
  var themes = document.querySelectorAll('.theme-change__option');
  let currentTheme = localStorage.getItem('theme');
  
  document.body.setAttribute('data-theme', currentTheme)

  let themeEvent = (e, i) => {
    localStorage.setItem('theme', e.target.dataset.theme);
    document.body.setAttribute('data-theme', e.target.dataset.theme)
  }
  themes.forEach((item) => {
      item.addEventListener('click', themeEvent)
  });

  window.addEventListener('click', function(e) {
    document.querySelectorAll('.dropdown').forEach(function(dropdown) {
      if (!dropdown.contains(e.target)) {
        dropdown.open = false;
      }
    });
  });
};

