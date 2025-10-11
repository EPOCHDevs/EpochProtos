# Next.js Usage Example for @epochlab/epoch-protos

## Installation
```bash
npm install @epochlab/epoch-protos
```

## Basic Import and Decode Example

### 1. Import the modules
```javascript
// For CommonJS/Node.js environments
const { epoch_proto } = require('@epochlab/epoch-protos/common');

// For ESM/Modern JavaScript
import { epoch_proto } from '@epochlab/epoch-protos/common';

// For specific web-optimized builds in Next.js
import { epoch_proto } from '@epochlab/epoch-protos/web/common';
```

### 2. Decoding Binary Data
```javascript
// Example: Decoding a Scalar message from binary
import { epoch_proto } from '@epochlab/epoch-protos/common';

// Assuming you have binary data (Uint8Array)
const binaryData = new Uint8Array([/* your binary data */]);

// Decode the binary data
try {
  const decodedScalar = epoch_proto.Scalar.decode(binaryData);
  console.log('Decoded:', decodedScalar);
  
  // Access the value
  if (decodedScalar.stringValue) {
    console.log('String value:', decodedScalar.stringValue);
  } else if (decodedScalar.doubleValue) {
    console.log('Double value:', decodedScalar.doubleValue);
  }
} catch (error) {
  console.error('Decode error:', error);
}
```

### 3. Full Example with ChartDef
```javascript
import { epoch_proto } from '@epochlab/epoch-protos/chart_def';

// Decode binary chart data
function decodeChartData(binaryBuffer) {
  try {
    // If you have a Buffer or ArrayBuffer, convert to Uint8Array
    const uint8Array = new Uint8Array(binaryBuffer);
    
    // Decode the ChartDef message
    const chartDef = epoch_proto.ChartDef.decode(uint8Array);
    
    // Access chart properties
    console.log('Chart Title:', chartDef.title);
    console.log('Chart Type:', chartDef.type);
    
    // Process series data
    if (chartDef.series && chartDef.series.length > 0) {
      chartDef.series.forEach((serie, index) => {
        console.log(`Series ${index}:`, serie.name);
        // Access data points
        if (serie.data) {
          console.log('Data points:', serie.data.values);
        }
      });
    }
    
    return chartDef;
  } catch (error) {
    console.error('Failed to decode chart data:', error);
    throw error;
  }
}
```

### 4. Next.js API Route Example
```javascript
// pages/api/decode-chart.js (Pages Router)
// or
// app/api/decode-chart/route.js (App Router)

import { epoch_proto } from '@epochlab/epoch-protos/chart_def';

export async function POST(request) {
  try {
    // Get binary data from request
    const buffer = await request.arrayBuffer();
    const uint8Array = new Uint8Array(buffer);
    
    // Decode the protobuf message
    const chartDef = epoch_proto.ChartDef.decode(uint8Array);
    
    // Return JSON response
    return Response.json({
      success: true,
      data: chartDef.toJSON()
    });
  } catch (error) {
    return Response.json({
      success: false,
      error: error.message
    }, { status: 400 });
  }
}
```

### 5. Client-Side Usage in Next.js Component
```jsx
// components/ChartViewer.jsx
import { useEffect, useState } from 'react';
import { epoch_proto } from '@epochlab/epoch-protos/web/chart_def';

export default function ChartViewer({ binaryData }) {
  const [chartData, setChartData] = useState(null);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    if (binaryData) {
      try {
        // Decode the binary data
        const decoded = epoch_proto.ChartDef.decode(binaryData);
        setChartData(decoded.toJSON());
      } catch (err) {
        setError(err.message);
      }
    }
  }, [binaryData]);
  
  if (error) {
    return <div>Error: {error}</div>;
  }
  
  if (!chartData) {
    return <div>Loading...</div>;
  }
  
  return (
    <div>
      <h2>{chartData.title}</h2>
      {/* Render your chart here */}
    </div>
  );
}
```

## Common Issues and Solutions

### 1. Module Resolution Issues
If you're getting import errors, try:
- Clear Next.js cache: `rm -rf .next`
- Reinstall packages: `rm -rf node_modules package-lock.json && npm install`
- Check your `next.config.js` for any transpilePackages configuration

### 2. Binary Data Handling
Make sure your binary data is properly formatted:
```javascript
// From Base64
const base64String = "your_base64_string";
const binaryString = atob(base64String);
const bytes = new Uint8Array(binaryString.length);
for (let i = 0; i < binaryString.length; i++) {
  bytes[i] = binaryString.charCodeAt(i);
}
const decoded = epoch_proto.Scalar.decode(bytes);

// From Hex
const hexString = "your_hex_string";
const bytes = new Uint8Array(hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
const decoded = epoch_proto.Scalar.decode(bytes);
```

### 3. TypeScript Support
The package includes TypeScript definitions. For proper typing:
```typescript
import { epoch_proto } from '@epochlab/epoch-protos/common';

// Type is automatically inferred
const scalar: epoch_proto.Scalar = epoch_proto.Scalar.create({
  doubleValue: 123.45
});

// Encode to binary
const buffer: Uint8Array = epoch_proto.Scalar.encode(scalar).finish();

// Decode from binary
const decoded: epoch_proto.Scalar = epoch_proto.Scalar.decode(buffer);
```

## Testing Your Integration
```javascript
// test-decode.js
import { epoch_proto } from '@epochlab/epoch-protos/common';

// Create a test message
const testScalar = epoch_proto.Scalar.create({
  stringValue: "Hello from Next.js!"
});

// Encode it
const encoded = epoch_proto.Scalar.encode(testScalar).finish();
console.log('Encoded bytes:', encoded);

// Decode it back
const decoded = epoch_proto.Scalar.decode(encoded);
console.log('Decoded value:', decoded.stringValue);

// Should output: "Hello from Next.js!"
```