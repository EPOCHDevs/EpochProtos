#!/bin/bash

# EpochProtos TypeScript/npm Publishing Script
# This script handles building and publishing TypeScript packages locally and remotely

set -e  # Exit on any error

# Configuration
PACKAGE_NAME="@epochlab/epoch-protos"
# Runtime choice: "google-protobuf" (protoc-gen-ts) or "protobufjs" (pbjs static, bundled)
TS_RUNTIME="protobufjs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get version from version manager
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r')
else
    VERSION="1.0.0"
fi

# Log the version being used
echo "Using version: $VERSION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking TypeScript prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    if [ "$TS_RUNTIME" = "google-protobuf" ]; then
        # protoc-gen-ts for google-protobuf style output
        if ! command -v protoc-gen-ts &> /dev/null; then
            log_info "Installing protoc-gen-ts..."
            npm install -g protoc-gen-ts
        fi
    else
        # protobufjs CLI for static JS + d.ts
        if ! command -v pbjs &> /dev/null; then
            log_info "Installing protobufjs CLI..."
            npm install -g protobufjs
        fi
        if ! command -v pbts &> /dev/null; then
            log_info "Installing protobufjs CLI typings tool..."
            npm install -g protobufjs
        fi
        # esbuild for bundling to zero external deps
        if ! command -v esbuild &> /dev/null; then
            log_info "Installing esbuild..."
            npm install -g esbuild
        fi
    fi
    
    log_success "TypeScript prerequisites check passed"
}

# Function to generate TypeScript protobuf files
generate_typescript_protos() {
    # Check if already generated
    if [ -f "$PROJECT_ROOT/build/.typescript_generated" ]; then
        log_info "TypeScript protos already generated, skipping..."
        return 0
    fi

    log_info "Generating TypeScript protobuf files..."

    cd "$PROJECT_ROOT"

    # Create build directory and generate protos
    mkdir -p build
    cd build
    if [ "$TS_RUNTIME" = "google-protobuf" ]; then
        cmake .. -DBUILD_PYTHON_PROTOS=OFF -DBUILD_TYPESCRIPT_PROTOS=ON
        make generate_typescript_protos setup_typescript_package
    else
        mkdir -p generated-typescript
        pbjs -t static-module -w commonjs -o generated-typescript/common.js ../proto/common.proto
        pbjs -t static-module -w commonjs -o generated-typescript/chart_def.js ../proto/chart_def.proto
        pbjs -t static-module -w commonjs -o generated-typescript/table_def.js ../proto/table_def.proto
        pbjs -t static-module -w commonjs -o generated-typescript/tearsheet.js ../proto/tearsheet.proto
        pbts -o generated-typescript/common.d.ts generated-typescript/common.js
        pbts -o generated-typescript/chart_def.d.ts generated-typescript/chart_def.js
        pbts -o generated-typescript/table_def.d.ts generated-typescript/table_def.js
        pbts -o generated-typescript/tearsheet.d.ts generated-typescript/tearsheet.js
    fi

    # Mark as generated
    touch .typescript_generated

    log_success "TypeScript protobuf files generated"
}

# Function to create TypeScript package structure
create_typescript_package() {
    log_info "Creating TypeScript package structure..."
    
    TS_PKG_DIR="$PROJECT_ROOT/typescript_package"
    rm -rf "$TS_PKG_DIR"
    mkdir -p "$TS_PKG_DIR/src"
    
    # Copy generated files
    if [ "$TS_RUNTIME" = "google-protobuf" ]; then
        cp -r "$PROJECT_ROOT/build/generated/typescript/"*.ts "$TS_PKG_DIR/src/"
    else
        cp -r "$PROJECT_ROOT/build/generated-typescript/"*.js "$TS_PKG_DIR/src/"
        cp -r "$PROJECT_ROOT/build/generated-typescript/"*.d.ts "$TS_PKG_DIR/src/"
    fi
    
    # Create enhanced package.json
    cat > "$TS_PKG_DIR/package.json" << EOF
{
  "name": "$PACKAGE_NAME",
  "version": "$VERSION",
  "description": "TypeScript definitions generated from Protocol Buffers for EpochFolio models - optimized for Next.js and web applications",
  "main": "dist/index.js",
  "module": "dist/index.esm.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.esm.js",
      "require": "./dist/index.js",
      "types": "./dist/index.d.ts"
    },
    "./common": {
      "import": "./dist/common.esm.js",
      "require": "./dist/common.js",
      "types": "./dist/common.d.ts"
    },
    "./chart_def": {
      "import": "./dist/chart_def.esm.js",
      "require": "./dist/chart_def.js",
      "types": "./dist/chart_def.d.ts"
    },
    "./table_def": {
      "import": "./dist/table_def.esm.js",
      "require": "./dist/table_def.js",
      "types": "./dist/table_def.d.ts"
    },
    "./tearsheet": {
      "import": "./dist/tearsheet.esm.js",
      "require": "./dist/tearsheet.js",
      "types": "./dist/tearsheet.d.ts"
    },
    "./web/common": {
      "import": "./dist/web/common.esm.js",
      "require": "./dist/web/common.js",
      "types": "./dist/common.d.ts"
    },
    "./web/chart_def": {
      "import": "./dist/web/chart_def.esm.js",
      "require": "./dist/web/chart_def.js",
      "types": "./dist/chart_def.d.ts"
    },
    "./web/table_def": {
      "import": "./dist/web/table_def.esm.js",
      "require": "./dist/web/table_def.js",
      "types": "./dist/table_def.d.ts"
    },
    "./web/tearsheet": {
      "import": "./dist/web/tearsheet.esm.js",
      "require": "./dist/web/tearsheet.js",
      "types": "./dist/tearsheet.d.ts"
    }
  },
  "files": [
    "dist/",
    "proto/",
    "README.md",
    "LICENSE"
  ],
  "scripts": {
    "build": "npm run build:cjs && npm run build:esm && npm run build:web && npm run build:types && npm run build:test",
    "build:cjs": "esbuild src/index.ts --bundle --platform=neutral --format=cjs --outfile=dist/index.js && esbuild src/common.js --bundle --platform=neutral --format=cjs --outfile=dist/common.js && esbuild src/chart_def.js --bundle --platform=neutral --format=cjs --outfile=dist/chart_def.js && esbuild src/table_def.js --bundle --platform=neutral --format=cjs --outfile=dist/table_def.js && esbuild src/tearsheet.js --bundle --platform=neutral --format=cjs --outfile=dist/tearsheet.js",
    "build:esm": "esbuild src/index.ts --bundle --platform=neutral --format=esm --outfile=dist/index.esm.js && esbuild src/common.js --bundle --platform=neutral --format=esm --outfile=dist/common.esm.js && esbuild src/chart_def.js --bundle --platform=neutral --format=esm --outfile=dist/chart_def.esm.js && esbuild src/table_def.js --bundle --platform=neutral --format=esm --outfile=dist/table_def.esm.js && esbuild src/tearsheet.js --bundle --platform=neutral --format=esm --outfile=dist/tearsheet.esm.js",
    "build:web": "npm run build:web:cjs && npm run build:web:esm && npm run build:types",
    "build:web:cjs": "esbuild src/common.js --bundle --platform=neutral --format=cjs --outfile=dist/web/common.js && esbuild src/chart_def.js --bundle --platform=neutral --format=cjs --outfile=dist/web/chart_def.js && esbuild src/table_def.js --bundle --platform=neutral --format=cjs --outfile=dist/web/table_def.js && esbuild src/tearsheet.js --bundle --platform=neutral --format=cjs --outfile=dist/web/tearsheet.js",
    "build:web:esm": "esbuild src/common.js --bundle --platform=neutral --format=esm --outfile=dist/web/common.esm.js && esbuild src/chart_def.js --bundle --platform=neutral --format=esm --outfile=dist/web/chart_def.esm.js && esbuild src/table_def.js --bundle --platform=neutral --format=esm --outfile=dist/web/table_def.esm.js && esbuild src/tearsheet.js --bundle --platform=neutral --format=esm --outfile=dist/web/tearsheet.esm.js",
    "build:types": "cp -f src/*.d.ts dist/ && cp -f src/index.ts dist/index.d.ts",
    "build:test": "esbuild src/test.ts --bundle --platform=neutral --format=cjs --outfile=dist/test.js",
    "clean": "rimraf dist/",
    "prepublishOnly": "test -d dist || npm run build",
    "test": "node dist/test.js",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  },
  "keywords": [
    "protobuf",
    "protocol-buffers",
    "typescript",
    "epochfolio",
    "financial",
    "portfolio",
    "analytics",
    "grpc",
    "charts",
    "tables",
    "nextjs",
    "react",
    "web",
    "browser",
    "esm",
    "tree-shaking"
  ],
  "author": "EpochLab <dev@epochlab.ai>",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/epochlab/epoch-protos.git"
  },
  "bugs": {
    "url": "https://github.com/epochlab/epoch-protos/issues"
  },
  "homepage": "https://github.com/epochlab/epoch-protos#readme",
  "dependencies": {
    "protobufjs": "^7.2.0"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "@typescript-eslint/eslint-plugin": "^5.0.0",
    "@typescript-eslint/parser": "^5.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.8.0",
    "rimraf": "^3.0.2",
    "typescript": "^5.0.0",
    "esbuild": "^0.21.0"
  },
  "publishConfig": {
    "registry": "https://registry.npmjs.org/",
    "access": "public"
  },
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  }
}
EOF

    # Create enhanced tsconfig.json
    cat > "$TS_PKG_DIR/tsconfig.json" << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020"],
    "module": "CommonJS",
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts"
  ]
}
EOF

    # Create index.ts file to export all modules
    cat > "$TS_PKG_DIR/src/index.ts" << EOF
// EpochProtos TypeScript Exports
// Auto-generated protobuf definitions for EpochFolio models

export * from './common';
export * from './chart_def';
export * from './table_def';
export * from './tearsheet';

// Re-export common types for convenience
export {
  EpochFolioDashboardWidget,
  EpochFolioType,
  AxisType,
  Scalar,
  Array as ProtoArray
} from './common';

export {
  ChartDef,
  AxisDef,
  LinesDef,
  BarDef,
  HeatMapDef,
  HistogramDef,
  BoxPlotDef,
  XRangeDef,
  PieDef,
  Point,
  Line
} from './chart_def';

export {
  Table,
  CardDef,
  ColumnDef,
  TableData,
  TableRow
} from './table_def';

export {
  TearSheet,
  FullTearSheet,
  CardDefList,
  ChartList,
  TableList
} from './tearsheet';
EOF

    # Create test file
    cat > "$TS_PKG_DIR/src/test.ts" << EOF
// Test file for EpochProtos TypeScript package

import * as common from './common';
import * as chart_def from './chart_def';
import * as table_def from './table_def';
import * as tearsheet from './tearsheet';

console.log('Testing EpochProtos TypeScript package...');

// Test basic imports
console.log('✅ Successfully imported modules:');
console.log('- common:', Object.keys(common).slice(0, 5).join(', '), '...');
console.log('- chart_def:', Object.keys(chart_def).slice(0, 5).join(', '), '...');
console.log('- table_def:', Object.keys(table_def).slice(0, 5).join(', '), '...');
console.log('- tearsheet:', Object.keys(tearsheet).slice(0, 5).join(', '), '...');

// Test that we can access the protobuf classes
if (common.epoch_proto && common.epoch_proto.Scalar) {
  console.log('✅ Scalar class found in common module');
}

if (chart_def.epoch_proto && chart_def.epoch_proto.ChartDef) {
  console.log('✅ ChartDef class found in chart_def module');
}

if (table_def.epoch_proto && table_def.epoch_proto.Table) {
  console.log('✅ Table class found in table_def module');
}

if (tearsheet.epoch_proto && tearsheet.epoch_proto.TearSheet) {
  console.log('✅ TearSheet class found in tearsheet module');
}

console.log('✅ TypeScript package test successful!');
EOF

    # Create .eslintrc.json
    cat > "$TS_PKG_DIR/.eslintrc.json" << EOF
{
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended"
  ],
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module"
  },
  "rules": {
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/no-explicit-any": "warn"
  }
}
EOF

    # Create .prettierrc
    cat > "$TS_PKG_DIR/.prettierrc" << EOF
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
EOF

    # Copy essential files
    cp "$PROJECT_ROOT/README.md" "$TS_PKG_DIR/" 2>/dev/null || true
    cp "$PROJECT_ROOT/LICENSE" "$TS_PKG_DIR/" 2>/dev/null || true
    
    # Copy proto files
    mkdir -p "$TS_PKG_DIR/proto"
    cp "$PROJECT_ROOT/proto/"*.proto "$TS_PKG_DIR/proto/" 2>/dev/null || true
    
    log_success "TypeScript package structure created in $TS_PKG_DIR"
}

# Function to build TypeScript package
build_typescript_package() {
    # Check if already built with correct version
    if [ -f "$PROJECT_ROOT/typescript_package/.built_version" ]; then
        BUILT_VERSION=$(cat "$PROJECT_ROOT/typescript_package/.built_version")
        if [ "$BUILT_VERSION" = "$VERSION" ] && [ -d "$PROJECT_ROOT/typescript_package/dist" ]; then
            log_info "TypeScript package already built for version $VERSION, skipping..."
            return 0
        fi
    fi

    log_info "Building TypeScript package..."

    cd "$PROJECT_ROOT/typescript_package"

    # Install dependencies (skip if node_modules exists)
    if [ ! -d "node_modules" ]; then
        npm install
    fi

    # Build the package (skip prepublishOnly since we're building manually)
    npm run build:cjs && npm run build:esm && npm run build:web && npm run build:types && npm run build:test

    # Mark build version
    echo "$VERSION" > .built_version

    log_success "TypeScript package built successfully"
    ls -la dist/
}

# Function to test TypeScript package locally
test_typescript_package_local() {
    log_info "Testing TypeScript package locally..."
    
    cd "$PROJECT_ROOT/typescript_package"
    
    # Run the test
    npm test
    
    log_success "TypeScript package local test passed"
}

# Function to publish to local npm registry (for testing)
publish_typescript_local() {
    log_info "Publishing TypeScript package locally..."
    
    cd "$PROJECT_ROOT/typescript_package"
    
    # Pack the package
    npm pack
    
    # Install globally for testing
    npm install -g ./*.tgz
    
    log_success "TypeScript package installed locally"
    log_info "You can now import $PACKAGE_NAME in TypeScript/JavaScript"
}

# Function to publish to npm (dry run)
publish_typescript_dry_run() {
    log_info "Running npm publish dry run..."
    
    cd "$PROJECT_ROOT/typescript_package"
    
    # Dry run
    npm publish --dry-run
    
    log_success "Dry run completed successfully"
}

# Function to publish to npm
publish_typescript_npm() {
    log_info "Publishing to npm..."
    
    cd "$PROJECT_ROOT/typescript_package"
    
    # Check if user is logged in
    if ! npm whoami &> /dev/null; then
        log_error "Not logged in to npm. Please run 'npm login' first"
        exit 1
    fi
    
    # Check if version already exists
    if npm view "$PACKAGE_NAME@$VERSION" version &> /dev/null; then
        log_warning "Version $VERSION already exists on npm"
        read -p "Do you want to publish anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Publishing cancelled"
            exit 0
        fi
    fi
    
    # Publish to npm
    npm publish
    
    log_success "Package published to npm"
    log_info "Install with: npm install $PACKAGE_NAME"
    log_info "Package URL: https://www.npmjs.com/package/$PACKAGE_NAME"
}

# Function to create test application
create_typescript_test_app() {
    log_info "Creating TypeScript test application..."
    
    TEST_APP_DIR="$PROJECT_ROOT/test_typescript_app"
    rm -rf "$TEST_APP_DIR"
    mkdir -p "$TEST_APP_DIR"
    
    cd "$TEST_APP_DIR"
    
    # Initialize npm project
    npm init -y
    
    # Install dependencies
    npm install typescript @types/node
    npm install "$PROJECT_ROOT/typescript_package/"*.tgz
    
    # Create tsconfig.json
    cat > "tsconfig.json" << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
EOF

    # Create test app
    cat > "test-app.ts" << EOF
import {
  ChartDef,
  EpochFolioDashboardWidget,
  Table,
  EpochFolioType,
  TearSheet,
  FullTearSheet
} from '$PACKAGE_NAME';

console.log('Testing EpochProtos in external TypeScript application...');

// Create a chart
const chart = new ChartDef();
chart.setId('external-test');
chart.setTitle('External Test Chart');
chart.setType(EpochFolioDashboardWidget.WidgetBar);
chart.setCategory('risk-analysis'); // Category is a string

console.log(\`Chart: \${chart.getTitle()}\`);

// Create a table
const table = new Table();
table.setTitle('External Test Table');
table.setType(EpochFolioDashboardWidget.WidgetDataTable);

console.log(\`Table: \${table.getTitle()}\`);

// Create a tearsheet
const tearsheet = new TearSheet();
console.log('✅ TearSheet created successfully');

// Create a full tearsheet
const fullTearSheet = new FullTearSheet();
console.log('✅ FullTearSheet created successfully');

console.log('🎉 External TypeScript application test successful!');
EOF

    # Compile and run
    npx tsc test-app.ts
    node test-app.js
    
    # Cleanup
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_APP_DIR"
    
    log_success "TypeScript test application passed"
}

# Function to create comprehensive Next.js documentation
create_nextjs_documentation() {
    log_info "Creating Next.js documentation..."
    
    cd "$PROJECT_ROOT/typescript_package"
    
    # Create comprehensive README for Next.js users
    cat > "README.md" << 'EOF'
# @epochlab/epoch-protos

TypeScript definitions generated from Protocol Buffers for EpochFolio models - optimized for Next.js and web applications.

## 🚀 Quick Start for Next.js

### Installation

```bash
npm install @epochlab/epoch-protos
# or
yarn add @epochlab/epoch-protos
# or
pnpm add @epochlab/epoch-protos
```

### Basic Usage

```typescript
import { ChartDef, EpochFolioDashboardWidget } from '@epochlab/epoch-protos';

// Create a chart definition
const chart = new ChartDef();
chart.setId('portfolio-returns');
chart.setTitle('Portfolio Returns Over Time');
chart.setType(EpochFolioDashboardWidget.WidgetLines);
chart.setCategory('strategy-benchmark'); // Category is a string

console.log(chart.getTitle()); // "Portfolio Returns Over Time"
```

## 📦 Bundle Size Optimization

### Web-Optimized Imports (Recommended for Web Apps)

For optimal bundle size in web applications, use the web-optimized imports:

```typescript
// ✅ Recommended: Web-optimized imports (smallest bundle)
import { ChartDef } from '@epochlab/epoch-protos/web/chart_def';
import { TearSheet } from '@epochlab/epoch-protos/web/tearsheet';
import { EpochFolioDashboardWidget } from '@epochlab/epoch-protos/web/common';

// ✅ Good: Standard tree-shaken imports
import { ChartDef } from '@epochlab/epoch-protos/chart_def';
import { TearSheet } from '@epochlab/epoch-protos/tearsheet';
import { EpochFolioDashboardWidget } from '@epochlab/epoch-protos/common';

// ❌ Avoid: Full import (largest bundle - 624KB+)
import { ChartDef, TearSheet, EpochFolioDashboardWidget } from '@epochlab/epoch-protos';
```

### Bundle Size Comparison

| Import Method | Bundle Size | Use Case |
|---------------|-------------|----------|
| `/web/*` imports | ~88-280KB per module | **Web apps (recommended)** |
| Individual imports | ~88-304KB per module | Node.js apps |
| Full import | 624KB+ | Development only |

## 🎯 Next.js Integration Examples

### Server-Side Rendering (SSR)

```typescript
// pages/api/charts.ts
import { NextApiRequest, NextApiResponse } from 'next';
import { ChartDef, EpochFolioDashboardWidget } from '@epochlab/epoch-protos';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const chart = new ChartDef();
  chart.setId('api-chart');
  chart.setTitle('Server-Generated Chart');
  chart.setType(EpochFolioDashboardWidget.WidgetBar);
  chart.setCategory('risk-analysis');
  
  res.status(200).json({
    chart: chart.toObject()
  });
}
```

### Client-Side Components

```typescript
// components/PortfolioChart.tsx
import React, { useEffect, useState } from 'react';
import { ChartDef, EpochFolioDashboardWidget } from '@epochlab/epoch-protos';

export default function PortfolioChart() {
  const [chart, setChart] = useState<ChartDef | null>(null);

  useEffect(() => {
    const chartDef = new ChartDef();
    chartDef.setId('portfolio-chart');
    chartDef.setTitle('Portfolio Performance');
    chartDef.setType(EpochFolioDashboardWidget.WidgetLines);
    chartDef.setCategory('strategy-benchmark');
    
    setChart(chartDef);
  }, []);

  if (!chart) return <div>Loading...</div>;

  return (
    <div>
      <h2>{chart.getTitle()}</h2>
      <p>Chart ID: {chart.getId()}</p>
    </div>
  );
}
```

### App Router (Next.js 13+)

```typescript
// app/dashboard/page.tsx
import { ChartDef, TearSheet, EpochFolioDashboardWidget } from '@epochlab/epoch-protos';

export default function DashboardPage() {
  const tearsheet = new TearSheet();
  
  return (
    <div>
      <h1>Portfolio Dashboard</h1>
      {/* Your dashboard content */}
    </div>
  );
}
```

## 📊 Available Models

### Common Types (`common.proto`)
- **Enums**: `EpochFolioDashboardWidget`, `EpochFolioType`, `AxisType`
- **Messages**: `Scalar`, `Array`

#### Available Widget Types:
```typescript
EpochFolioDashboardWidget.WidgetUnspecified    // 0
EpochFolioDashboardWidget.WidgetCard           // 1
EpochFolioDashboardWidget.WidgetLines          // 2
EpochFolioDashboardWidget.WidgetBar            // 3
EpochFolioDashboardWidget.WidgetDataTable      // 4
EpochFolioDashboardWidget.WidgetXRange         // 5
EpochFolioDashboardWidget.WidgetHistogram      // 6
EpochFolioDashboardWidget.WidgetPie            // 7
EpochFolioDashboardWidget.WidgetHeatMap        // 8
EpochFolioDashboardWidget.WidgetBoxPlot        // 9
EpochFolioDashboardWidget.WidgetArea           // 10
EpochFolioDashboardWidget.WidgetColumn         // 11
```

### Chart Definitions (`chart_def.proto`)
- `ChartDef`, `LinesDef`, `BarDef`, `HeatMapDef`, `HistogramDef`
- `BoxPlotDef`, `XRangeDef`, `PieDef`, `Point`, `Line`

### Table Definitions (`table_def.proto`)
- `Table`, `CardDef`, `ColumnDef`, `TableData`, `TableRow`

### TearSheet Definitions (`tearsheet.proto`)
- `TearSheet`, `FullTearSheet`, `CardDefList`, `ChartList`, `TableList`

## 🔧 TypeScript Configuration

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### next.config.js
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    esmExternals: true,
  },
  webpack: (config) => {
    // Ensure proper module resolution
    config.resolve.fallback = {
      ...config.resolve.fallback,
      fs: false,
    };
    return config;
  },
};

module.exports = nextConfig;
```

## 🎨 Usage Patterns

### Creating Dashboard Widgets

```typescript
import { 
  ChartDef, 
  Table, 
  CardDef,
  EpochFolioDashboardWidget
} from '@epochlab/epoch-protos';

// Create a line chart
const lineChart = new ChartDef();
lineChart.setId('returns-chart');
lineChart.setTitle('Portfolio Returns');
lineChart.setType(EpochFolioDashboardWidget.WidgetLines);
lineChart.setCategory('strategy-benchmark'); // Category is a string

// Create a data table
const dataTable = new Table();
dataTable.setTitle('Holdings Summary');
dataTable.setType(EpochFolioDashboardWidget.WidgetDataTable);

// Create a card widget
const card = new CardDef();
card.setTitle('Total Return');
card.setValue('12.5%');
```

### Working with TearSheets

```typescript
import { TearSheet, FullTearSheet, ChartDef, Table } from '@epochlab/epoch-protos';

// Create a single tearsheet
const tearsheet = new TearSheet();

// Add charts to tearsheet
const chart = new ChartDef();
chart.setId('risk-chart');
chart.setTitle('Risk Analysis');
chart.setType(EpochFolioDashboardWidget.WidgetLines);
chart.setCategory('risk-analysis');
tearsheet.getChartsList().push(chart);

// Create a full tearsheet with multiple categories
const fullTearSheet = new FullTearSheet();
fullTearSheet.getCategoriesMap().set('risk', tearsheet);
```

## 🚀 Performance Tips

1. **Use Web-Optimized Imports**: Use `/web/*` imports for smallest bundle size
2. **Lazy Loading**: Load protobuf models only when needed
3. **Server-Side Generation**: Pre-generate data on the server
4. **Bundle Analysis**: Use `@next/bundle-analyzer` to monitor bundle size
5. **Code Splitting**: Split protobuf usage into separate chunks

```typescript
// ✅ Best: Web-optimized lazy loading
const loadChart = async () => {
  const { ChartDef, EpochFolioDashboardWidget } = await import('@epochlab/epoch-protos/web/chart_def');
  const chart = new ChartDef();
  chart.setType(EpochFolioDashboardWidget.WidgetLines);
  return chart;
};

// ✅ Good: Standard lazy loading
const loadChart = async () => {
  const { ChartDef, EpochFolioDashboardWidget } = await import('@epochlab/epoch-protos/chart_def');
  const chart = new ChartDef();
  chart.setType(EpochFolioDashboardWidget.WidgetBar);
  return chart;
};

// ✅ Good: Server-side generation
export async function getServerSideProps() {
  const { ChartDef, EpochFolioDashboardWidget } = await import('@epochlab/epoch-protos/web/chart_def');
  const chart = new ChartDef();
  chart.setType(EpochFolioDashboardWidget.WidgetLines);
  chart.setCategory('risk-analysis');
  // ... populate chart data
  
  return {
    props: {
      chartData: chart.toObject()
    }
  };
}

// ✅ Good: Dynamic imports for code splitting
const ChartComponent = dynamic(() => import('./ChartComponent'), {
  loading: () => <div>Loading chart...</div>
});
```

## 🔍 Debugging

### Enable Protobuf Debugging
```typescript
// Enable debug logging
import { util } from 'protobufjs';
util.debug = true;
```

### Common Issues

1. **Module Resolution**: Ensure your `tsconfig.json` has proper module resolution
2. **Bundle Size**: Use tree-shaking to reduce bundle size
3. **SSR Compatibility**: Protobuf models work in both server and client environments

## 📚 API Reference

### ChartDef Methods
```typescript
chart.setId(id: string): void
chart.getId(): string
chart.setTitle(title: string): void
chart.getTitle(): string
chart.setType(type: EpochFolioDashboardWidget): void
chart.getType(): EpochFolioDashboardWidget
chart.setCategory(category: string): void
chart.getCategory(): string
chart.setYAxis(axis: AxisDef): void
chart.getYAxis(): AxisDef
chart.setXAxis(axis: AxisDef): void
chart.getXAxis(): AxisDef
chart.toObject(): object
chart.fromObject(obj: object): void
```

### Table Methods
```typescript
table.setTitle(title: string): void
table.getTitle(): string
table.setType(type: EpochFolioDashboardWidget): void
table.getType(): EpochFolioDashboardWidget
table.getColumnsList(): ColumnDef[]
table.getDataList(): TableRow[]
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Next.js applications
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [NPM Package](https://www.npmjs.com/package/@epochlab/epoch-protos)
- [GitHub Repository](https://github.com/epochlab/epoch-protos)
- [Documentation](https://github.com/epochlab/epoch-protos#readme)
EOF

    log_success "Next.js documentation created"
}

# Function to build and deploy complete package
build_and_deploy() {
    log_info "Building and deploying complete TypeScript package..."
    
    # Run the complete workflow
    check_prerequisites
    generate_typescript_protos
    create_typescript_package
    build_typescript_package
    test_typescript_package_local
    create_nextjs_documentation
    
    log_success "Package built successfully"
    log_info "Package ready for deployment in: $PROJECT_ROOT/typescript_package"
    log_info "Run 'npm run dry-run' to test publishing"
    log_info "Run 'npm run publish' to publish to npm"
}

# Main workflow function
run_typescript_workflow() {
    local command="${1:-all}"
    
    case $command in
        "check")
            check_prerequisites
            ;;
        "generate")
            check_prerequisites
            generate_typescript_protos
            ;;
        "package")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            ;;
        "build")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            ;;
        "test")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            test_typescript_package_local
            ;;
        "install-local")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            publish_typescript_local
            ;;
        "dry-run")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            test_typescript_package_local
            publish_typescript_dry_run
            ;;
        "publish")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            test_typescript_package_local
            publish_typescript_dry_run
            publish_typescript_npm
            ;;
        "test-app")
            create_typescript_test_app
            ;;
        "docs")
            create_nextjs_documentation
            ;;
        "deploy")
            build_and_deploy
            ;;
        "all")
            check_prerequisites
            generate_typescript_protos
            create_typescript_package
            build_typescript_package
            test_typescript_package_local
            ;;
        *)
            echo "Usage: $0 [check|generate|package|build|test|install-local|dry-run|publish|test-app|docs|deploy|all]"
            echo ""
            echo "Commands:"
            echo "  check         - Check prerequisites"
            echo "  generate      - Generate TypeScript protobuf files"
            echo "  package       - Create TypeScript package structure"
            echo "  build         - Build TypeScript package"
            echo "  test          - Test TypeScript package locally"
            echo "  install-local - Install package locally for testing"
            echo "  dry-run       - Run npm publish dry run"
            echo "  publish       - Publish to npm"
            echo "  test-app      - Create and test external application"
            echo "  docs          - Create Next.js documentation"
            echo "  deploy        - Build and prepare complete package for deployment"
            echo "  all           - Run all steps except publishing (default)"
            exit 1
            ;;
    esac
}

# Run the workflow
run_typescript_workflow "$@"
