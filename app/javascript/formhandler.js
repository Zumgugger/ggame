document.addEventListener('DOMContentLoaded', () => {
  const optionSelect = document.getElementById('event_option_id');
  const objectNames = JSON.parse(optionSelect.getAttribute('data-names'));

  const minepointsContainer = document.getElementById('minepoints');
  const targetGroupContainer = document.getElementById('target_group');
  const targetContainer = document.getElementById('target');

  optionSelect.addEventListener('change', () => {
    const selectedName = objectNames.find(obj => obj.id === parseInt(optionSelect.value))?.name;

    switch (selectedName) {
      default:
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'block';
        break;
      case 'hat Posten geholt':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'block';
        break;
      case 'hat Mine gesetzt':
        minepointsContainer.style.display = 'block';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'block';
        break;
      case 'hat Gruppe fotografiert':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'block';
        targetContainer.style.display = 'none';
        break;
      case 'hat sondiert':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'block';
        break;
      case 'hat spioniert':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'block';
        targetContainer.style.display = 'none';
        break;
      case 'hat Foto bemerkt':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'block';
        targetContainer.style.display = 'none';
        break;
      case 'Spionageabwehr':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'none';
        break;
      case 'hat Kopfgeld gesetzt':
        minepointsContainer.style.display = 'block';
        targetGroupContainer.style.display = 'block';
        targetContainer.style.display = 'none';
        break;
      case 'hat Mine entschärft':
        minepointsContainer.style.display = 'none';
        targetGroupContainer.style.display = 'none';
        targetContainer.style.display = 'block';
        break;
    }
  });
});









// document.addEventListener('DOMContentLoaded', () => {
//   const optionSelect = document.getElementById('event_option_id');
//   const minepointsContainer = document.getElementById('minepoints');
//   const targetGroupContainer = document.getElementById('target_group');
//   const targetContainer = document.getElementById('target'); 

//   optionSelect.addEventListener('change', () => {
//     switch (optionSelect.value) {
//       case '2':
//         minepointsContainer.style.display = 'block';
//         targetGroupContainer.style.display = 'none';
//         targetContainer.style.display = 'none';
//         break;
//       case '3':
//       case '7':
//         minepointsContainer.style.display = 'none';
//         targetGroupContainer.style.display = 'block';
//         targetContainer.style.display = 'none';
//         break;
//       case '1':
//         minepointsContainer.style.display = 'none';
//         targetGroupContainer.style.display = 'none';
//         targetContainer.style.display = 'block';
//         break;
//       default:
//         minepointsContainer.style.display = 'none';
//         targetGroupContainer.style.display = 'none';
//         targetContainer.style.display = 'none';
//         break;
//     }
//   });
// });