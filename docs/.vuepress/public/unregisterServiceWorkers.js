/**
 * This script responsibly unregisters all service workers.
 */

// if(window.navigator && navigator.serviceWorker) {
//   navigator.serviceWorker.getRegistrations()
//     .then( function(registrations) {
//       if (registrations.length > 0) {
//         for (var i = 0; i < registrations.length; i++) {
//           registrations[i].unregister();
//           console.log(registrations[i] + ' is now unregistered.');
//         }
//       } else {
//         console.log('There are no service workers registered for this website.');
//       }
//     }
//   );
// }