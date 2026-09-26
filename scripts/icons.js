import sharp from 'sharp';

for (const size of [192, 512]) {
  await sharp('apps/web/public/icon.svg').resize(size, size).png().toFile(`apps/web/public/icon-${size}.png`);
}
await sharp('apps/web/public/icon.svg').resize(400, 400).extend({
  top: 56, bottom: 56, left: 56, right: 56, background: '#fafafa',
}).png().toFile('apps/web/public/icon-maskable-512.png');
