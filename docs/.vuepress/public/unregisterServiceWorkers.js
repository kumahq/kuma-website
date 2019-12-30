/**
 * This script responsibly unregisters all service workers.
 */

if(window.navigator && navigator.serviceWorker) {
  navigator.serviceWorker.getRegistrations()
    .then( function(registrations) {
      if (registrations.length > 0) {
        for (var i = 0; i < registrations.length; i++) {
          registrations[i].unregister();
        }
      }
    }
  );
}