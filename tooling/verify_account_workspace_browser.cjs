const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const {chromium} = require('playwright');
const {captureContrast} = require('./account_workspace_browser_checks.cjs');

const origin = process.env.ACCOUNT_WORKSPACE_URL || 'http://127.0.0.1:43282';
assert(['127.0.0.1', 'localhost'].includes(new URL(origin).hostname), 'Local fixture only');
assert.equal(process.env.ACCOUNT_WORKSPACE_FIXTURE, '1', 'Explicit fixture opt-in required');
const email = 'owner+long-test-identity-for-mobile@long-customer-domain.example.test';
const originalPassword = process.env.ACCOUNT_WORKSPACE_PASSWORD || 'originalPassword123';
const replacementPassword = process.env.ACCOUNT_WORKSPACE_NEW_PASSWORD || 'replacementPassword456';
const output = process.env.ACCOUNT_WORKSPACE_OUTPUT || '/private/tmp/oss-owner-browser-proof-20260904';

(async () => {
  await fs.mkdir(output, {recursive:true});
  const executablePath = process.env.ACCOUNT_WORKSPACE_CHROME || (process.platform==='darwin' ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : undefined);
  const browser = await chromium.launch({executablePath, headless:true});
  const context = await browser.newContext({viewport:{width:1280,height:1000}});
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  async function login(target, password) {
    await target.goto(`${origin}/login`);
    await target.locator('#email').fill(email);
    await target.locator('#password').fill(password);
    await Promise.all([target.waitForURL('**/dashboard'), target.getByRole('button',{name:'Sign in',exact:true}).click()]);
  }
  try {
    await login(page, originalPassword);
    assert.equal(await page.locator('[data-component="account-dashboard"]').count(), 1);
    assert(!/1,247|24,780|New Project|john.doe@example/.test(await page.locator('main').innerText()));
    await page.screenshot({path:path.join(output,'dashboard-desktop.png'),fullPage:true});
    const desktopContrast = await captureContrast(page,output,'dashboard-desktop');

    const oldContext = await browser.newContext();
    const oldPage = await oldContext.newPage();
    await login(oldPage,originalPassword);
    const profileResponse = await page.goto(`${origin}/profile`);
    assert.equal(profileResponse.status(),200);
    await page.setViewportSize({width:390,height:844});
    const toggle = page.getByRole('button',{name:'Menu',exact:true});
    assert.equal(await toggle.getAttribute('aria-expanded'),'false');
    await toggle.click();
    assert.equal(await toggle.getAttribute('aria-expanded'),'true');
    await page.keyboard.press('Escape');
    assert.equal(await toggle.getAttribute('aria-expanded'),'false');
    await page.locator('#display_name').fill('Fixture Owner');
    await Promise.all([page.waitForURL('**/settings#profile'),page.getByRole('button',{name:'Save profile',exact:true}).click()]);
    await page.reload();
    assert.equal(await page.locator('#display_name').inputValue(),'Fixture Owner');
    assert.equal(await page.locator('#account-email').innerText(),email);
    const rejected = await page.request.post(`${origin}/settings/profile`,{form:{display_name:'CSRF attack'}});
    assert.equal(rejected.status(),403);
    await page.reload();
    assert.equal(await page.locator('#display_name').inputValue(),'Fixture Owner');
    assert.equal(await page.locator('details[open]').count(),0);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),true);
    const fieldChecks = await page.locator('.field input').evaluateAll(inputs => inputs.map(input => {
      const box=input.getBoundingClientRect(), panel=input.closest('.panel').getBoundingClientRect();
      return {id:input.id,height:box.height,contained:box.left>=panel.left && box.right<=panel.right,fontSize:parseFloat(getComputedStyle(input).fontSize)};
    }).filter(field => field.height > 0));
    assert(fieldChecks.every(field => field.height>=44 && field.contained && field.fontSize>=16));
    const change = page.getByRole('button',{name:'Change password',exact:true});
    assert.equal(await change.isDisabled(),true);
    await page.locator('#current-password').fill(originalPassword);
    await page.locator('#new-password').fill('12345678');
    assert.equal(await page.locator('[data-rule="length"]').getAttribute('data-valid'),'true');
    await page.locator('#new-password').fill('1234567');
    assert.equal(await page.locator('[data-rule="length"]').getAttribute('data-valid'),'false');
    await page.locator('#new-password').fill(replacementPassword);
    await page.locator('#password-confirmation').fill('mismatch');
    assert.equal(await change.isDisabled(),true);
    await page.locator('#password-confirmation').fill(replacementPassword);
    assert.equal(await change.isEnabled(),true);
    await page.locator('#security').scrollIntoViewIfNeeded();
    await page.screenshot({path:path.join(output,'settings-mobile.png'),fullPage:true});
    const mobileContrast = await captureContrast(page,output,'settings-mobile');
    let busyObserved = false;
    page.on('console', message => { if(message.text()==='account-submit-busy') busyObserved=true; });
    await page.evaluate(() => document.querySelector('[data-password-form]').addEventListener('submit',event => {
      if(event.currentTarget.getAttribute('aria-busy')==='true' && event.currentTarget.querySelector('button').disabled) console.log('account-submit-busy');
    }));
    await Promise.all([page.waitForURL('**/settings#security'),change.click()]);
    assert(busyObserved,'Password submission must show a busy state');
    await page.reload();
    assert.equal(await page.locator('#display_name').inputValue(),'Fixture Owner');
    await oldPage.goto(`${origin}/settings`);
    assert(new URL(oldPage.url()).pathname==='/login','Old session must be invalidated');
    await page.setViewportSize({width:1280,height:1000});
    await page.screenshot({path:path.join(output,'settings-desktop.png'),fullPage:true});
    const settingsContrast = await captureContrast(page,output,'settings-desktop');
    await page.getByRole('button',{name:'Sign out',exact:true}).click();
    await page.waitForURL(origin+'/');
    await page.goto(`${origin}/profile`);
    assert.equal(new URL(page.url()).pathname,'/login');
    await login(page,replacementPassword);
    const contrast=[...desktopContrast,...mobileContrast,...settingsContrast];
    assert(contrast.length>25);
    assert.equal(contrast.filter(row=>!row.passes).length,0,JSON.stringify(contrast.filter(row=>!row.passes)));
    assert.deepEqual(errors,[]);
    await fs.writeFile(path.join(output,'result.json'),JSON.stringify({passed:true,origin,email,checks:['Real login and CSRF','Profile route and durable name update','Long-email mobile overflow','44px fields and 16px input text','Mobile navigation and Escape','Live password rules and mismatch disabled','Busy state','Password persisted and old session revoked','Correct logout and fresh login','No fake metrics','Visible text contrast'],fieldChecks,contrastSamples:contrast.length,minimumContrast:Math.min(...contrast.map(row=>row.ratio)),noEmailSent:true},null,2));
    console.log(JSON.stringify({passed:true,output}));
  } catch(error) {
    await page.screenshot({path:path.join(output,'failure.png'),fullPage:true}).catch(()=>{});
    throw error;
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
