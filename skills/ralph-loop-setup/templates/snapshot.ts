/**
 * Ralph Loop Visual Snapshot Script
 *
 * Captures screenshots of key pages for before/after comparison.
 * Focuses on layout and component structure, not data content.
 *
 * Usage:
 *   npx ts-node scripts/ralph/snapshot.ts before
 *   npx ts-node scripts/ralph/snapshot.ts after
 *   npx ts-node scripts/ralph/snapshot.ts before --run-id 20260111-120000
 *
 * Configuration:
 *   Edit SNAPSHOT_CONFIG below or use scripts/ralph/snapshot-config.json
 */

import { chromium, Browser, Page } from 'playwright'
import * as fs from 'fs'
import * as path from 'path'

// ============================================
// CONFIGURATION - Edit for your project
// ============================================

interface SnapshotPage {
  name: string
  path: string
  /** Optional selector to screenshot specific element instead of full page */
  selector?: string
  /** Wait for this selector before capturing (useful for async content) */
  waitFor?: string
  /** Additional delay in ms after page load */
  delay?: number
}

interface SnapshotConfig {
  baseUrl: string
  viewport: { width: number; height: number }
  /** Directory to store snapshots (relative to project root) */
  outputDir: string
  pages: SnapshotPage[]
}

const DEFAULT_CONFIG: SnapshotConfig = {
  baseUrl: 'http://localhost:3000',
  viewport: { width: 1280, height: 800 },
  outputDir: 'scripts/ralph/snapshots',
  pages: [
    // Add your pages here - example:
    // { name: 'dashboard', path: '/dashboard', waitFor: '[data-testid="dashboard"]' },
    // { name: 'settings', path: '/settings' },
  ],
}

// ============================================
// SCRIPT LOGIC - Usually no changes needed
// ============================================

async function loadConfig(): Promise<SnapshotConfig> {
  const configPath = path.join(process.cwd(), 'scripts/ralph/snapshot-config.json')

  if (fs.existsSync(configPath)) {
    const configFile = fs.readFileSync(configPath, 'utf-8')
    const fileConfig = JSON.parse(configFile)
    return { ...DEFAULT_CONFIG, ...fileConfig }
  }

  return DEFAULT_CONFIG
}

async function captureSnapshots(phase: 'before' | 'after', runId: string) {
  const config = await loadConfig()

  if (config.pages.length === 0) {
    console.log('No pages configured for snapshots. Edit snapshot-config.json or snapshot.ts')
    return
  }

  const outputDir = path.join(process.cwd(), config.outputDir, runId, phase)
  fs.mkdirSync(outputDir, { recursive: true })

  console.log(`\n📸 Capturing ${phase} snapshots...`)
  console.log(`   Run ID: ${runId}`)
  console.log(`   Output: ${outputDir}`)
  console.log(`   Pages: ${config.pages.length}`)
  console.log('')

  let browser: Browser | null = null

  try {
    browser = await chromium.launch({ headless: true })
    const context = await browser.newContext({
      viewport: config.viewport,
      // Ignore HTTPS errors for local dev
      ignoreHTTPSErrors: true,
    })

    const page: Page = await context.newPage()

    for (const pageConfig of config.pages) {
      const url = `${config.baseUrl}${pageConfig.path}`
      const filename = `${pageConfig.name}.png`
      const filepath = path.join(outputDir, filename)

      try {
        console.log(`   Capturing: ${pageConfig.name} (${pageConfig.path})`)

        await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 })

        // Wait for specific selector if configured
        if (pageConfig.waitFor) {
          await page.waitForSelector(pageConfig.waitFor, { timeout: 10000 })
        }

        // Additional delay if needed
        if (pageConfig.delay) {
          await page.waitForTimeout(pageConfig.delay)
        }

        // Capture specific element or full page
        if (pageConfig.selector) {
          const element = await page.$(pageConfig.selector)
          if (element) {
            await element.screenshot({ path: filepath })
          } else {
            console.log(`   ⚠️  Selector not found: ${pageConfig.selector}`)
            await page.screenshot({ path: filepath, fullPage: false })
          }
        } else {
          await page.screenshot({ path: filepath, fullPage: false })
        }

        console.log(`   ✓ Saved: ${filename}`)
      } catch (error) {
        console.log(`   ✗ Failed: ${pageConfig.name} - ${error}`)
      }
    }

    // Write manifest for easy reference
    const manifest = {
      phase,
      runId,
      timestamp: new Date().toISOString(),
      config: {
        baseUrl: config.baseUrl,
        viewport: config.viewport,
      },
      pages: config.pages.map((p) => ({
        name: p.name,
        path: p.path,
        file: `${p.name}.png`,
      })),
    }

    fs.writeFileSync(path.join(outputDir, 'manifest.json'), JSON.stringify(manifest, null, 2))

    console.log('')
    console.log(`✅ ${phase} snapshots complete: ${outputDir}`)
  } finally {
    if (browser) {
      await browser.close()
    }
  }
}

function generateRunId(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hour = String(now.getHours()).padStart(2, '0')
  const min = String(now.getMinutes()).padStart(2, '0')
  const sec = String(now.getSeconds()).padStart(2, '0')
  return `${year}${month}${day}-${hour}${min}${sec}`
}

async function main() {
  const args = process.argv.slice(2)

  if (args.length === 0 || !['before', 'after'].includes(args[0])) {
    console.log('Usage: npx ts-node scripts/ralph/snapshot.ts <before|after> [--run-id ID]')
    console.log('')
    console.log('Examples:')
    console.log('  npx ts-node scripts/ralph/snapshot.ts before')
    console.log('  npx ts-node scripts/ralph/snapshot.ts after --run-id 20260111-120000')
    process.exit(1)
  }

  const phase = args[0] as 'before' | 'after'

  // Parse --run-id flag
  let runId = generateRunId()
  const runIdIndex = args.indexOf('--run-id')
  if (runIdIndex !== -1 && args[runIdIndex + 1]) {
    runId = args[runIdIndex + 1]
  }

  // For 'after' phase, try to find most recent 'before' run if no run-id specified
  if (phase === 'after' && runIdIndex === -1) {
    const config = await loadConfig()
    const snapshotDir = path.join(process.cwd(), config.outputDir)
    if (fs.existsSync(snapshotDir)) {
      const runs = fs
        .readdirSync(snapshotDir)
        .filter((d) => fs.existsSync(path.join(snapshotDir, d, 'before')))
        .sort()
        .reverse()

      if (runs.length > 0) {
        runId = runs[0]
        console.log(`Using most recent run: ${runId}`)
      }
    }
  }

  await captureSnapshots(phase, runId)
}

main().catch(console.error)
