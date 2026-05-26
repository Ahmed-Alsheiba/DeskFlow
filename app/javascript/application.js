// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "chart.js"
import "chartkick"

function autoHideFlash() {
	try {
		const wrapper = document.querySelector('.fixed.top-20');
		if (!wrapper) return;
		const messages = wrapper.querySelectorAll('.pointer-events-auto');
		if (!messages.length) return;
		// auto-hide after 5 seconds
		setTimeout(() => {
			messages.forEach(msg => {
				msg.classList.add('opacity-0', 'transition', 'duration-500');
				// remove after transition
				setTimeout(() => msg.remove(), 500);
			});
		}, 5000);
	} catch (e) {
		console.error(e);
	}
}

document.addEventListener('turbo:load', autoHideFlash);
document.addEventListener('DOMContentLoaded', autoHideFlash);
