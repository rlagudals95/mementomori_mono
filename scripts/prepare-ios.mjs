import { copyFile, mkdir } from 'node:fs/promises';
import sharp from 'sharp';
await mkdir('apps/ios/Resources', { recursive: true });
await copyFile('node_modules/pretendard/dist/public/variable/PretendardVariable.ttf', 'apps/ios/Resources/PretendardVariable.ttf');
const icon = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#151515"/><path d="M300 294H724M300 730H724M328 294C328 445 430 464 512 512C430 560 328 579 328 730M696 294C696 445 594 464 512 512C594 560 696 579 696 730" stroke="#fafafa" stroke-width="28" fill="none"/><circle cx="512" cy="648" r="20" fill="#fafafa"/></svg>`;
await sharp(Buffer.from(icon)).png().toFile('apps/ios/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png');
console.log('Prepared iOS font and icon');
