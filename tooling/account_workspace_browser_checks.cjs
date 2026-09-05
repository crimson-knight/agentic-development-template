const fs = require('node:fs/promises');
const path = require('node:path');

async function captureContrast(page, output, label) {
  const rows = await page.evaluate(() => {
    const color = value => {
      const parts = value.match(/[\d.]+/g).map(Number);
      return [parts[0], parts[1], parts[2], parts.length > 3 ? parts[3] : 1];
    };
    const over = (foreground, background) => foreground.slice(0, 3).map((part, index) =>
      part * foreground[3] + background[index] * (1 - foreground[3]));
    const luminance = rgb => rgb.map(part => {
      const value = part / 255;
      return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
    }).reduce((sum, part, index) => sum + part * [0.2126, 0.7152, 0.0722][index], 0);
    const root = document.querySelector('.workspace');
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const measured = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      const element = node.parentElement;
      const text = node.textContent.trim();
      if (!text || element.closest('script,style,button:disabled,[hidden]')) continue;
      let concealed = false;
      for (let parent = element; parent; parent = parent.parentElement) {
        if (parent.tagName === 'DETAILS' && !parent.open && !parent.querySelector(':scope > summary')?.contains(element)) {
          concealed = true;
          break;
        }
      }
      if (concealed) continue;
      const range = document.createRange();
      range.selectNodeContents(node);
      if (![...range.getClientRects()].some(rect => rect.width && rect.height)) continue;
      const style = getComputedStyle(element);
      if (style.visibility === 'hidden') continue;
      const backgrounds = [];
      for (let parent = element; parent; parent = parent.parentElement) {
        backgrounds.unshift(color(getComputedStyle(parent).backgroundColor));
      }
      const background = backgrounds.reduce((under, paint) => over(paint, under), [255, 255, 255]);
      const foreground = over(color(style.color), background);
      const levels = [luminance(background), luminance(foreground)].sort((a, b) => b - a);
      const ratio = (levels[0] + 0.05) / (levels[1] + 0.05);
      const size = parseFloat(style.fontSize), weight = parseInt(style.fontWeight, 10);
      const minimum = size >= 24 || size >= 18.6667 && weight >= 700 ? 3 : 4.5;
      measured.push({text: text.slice(0, 100), tag: element.tagName, class: element.className,
        foreground, background, fontSize: size, fontWeight: weight,
        ratio: Number(ratio.toFixed(3)), minimum, passes: ratio >= minimum});
    }
    return measured;
  });
  await fs.writeFile(path.join(output, `${label}-contrast.json`), JSON.stringify(rows, null, 2));
  return rows;
}

module.exports = {captureContrast};
