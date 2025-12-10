import { createTimeline, svg } from "animejs"

document.addEventListener("DOMContentLoaded", () => {
  const waves = document.querySelector('.waves.waves--type-1');

  if (waves !== null) {
    const delayAmt = 100;
    const tl = createTimeline({
      defaults: {
        ease: 'inOutSine',
        duration: 800
      }
    });

    // this is a FOUC prevention technique.
    // on load, set the `display` to `block` instead of `none`.
    waves.style.display = 'block';
    // trigger the timeline animations
    tl
    // animate path group 1
      .add(svg.createDrawable('.waves-group-1 path'), {
        draw: '0 1',
        delay: (_el, i) => i * delayAmt
      }, '+=300')
    // animate path group 2
      .add(svg.createDrawable('.waves-group-2 path'), {
        draw: '0 1',
        delay: (_el, i) => i * delayAmt
      }, '-=600')
    // animate path group 3
      .add(svg.createDrawable('.waves-group-3 path'), {
        draw: '0 1',
        delay: (_el, i) => i * delayAmt
      }, '-=600');
  }
});
