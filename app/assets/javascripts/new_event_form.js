// document.addEventListener("turbo:load", function() {
//     const actionSelect = document.getElementById('action');
//     const minepoints = document.getElementById('minepoints');
//     const target = document.getElementById('target');
//     const targetGroup = document.getElementById('target_group');

//     minepoints.style.display = 'none';
//     targetGroup.style.display = 'none';

//     // Function to handle the change event
//     function handleActionChange() {
//         const selectedAction = actionSelect.options[actionSelect.selectedIndex].text;

//         minepoints.style.display = 'none';
//         targetGroup.style.display = 'none';
//         target.style.display = 'block';

//         if (selectedAction === "hat Mine gesetzt" || selectedAction === "hat Kopfgeld gesetzt") {
//             minepoints.style.display = 'block';
//             targetGroup.style.display = 'none';
//         } else if (selectedAction === "hat Posten geholt" || selectedAction === "hat sondiert") {
//             targetGroup.style.display = 'none';
//         } else if (selectedAction === "hat Gruppe fotografiert" || selectedAction === "hat spioniert" || selectedAction === "hat Foto bemerkt") {
//             targetGroup.style.display = 'block';
//         } else if (selectedAction === "Spionageabwehr") {
//             targetGroup.style.display = 'none';
//         }
//     }

//     // Add the change event listener
//     actionSelect.addEventListener('change', handleActionChange);

//     // Manually trigger the change event on page load
//     actionSelect.dispatchEvent(new Event('change'));
// });

// actionSelect.addEventListener('change', function () {
//     handleActionChange();
//     actionSelect.closest('form').submit(); // Submit the form on change
// });
