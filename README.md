# EpochProtos

Protocol Buffer definitions for EpochFolio models, generating C++, TypeScript, and Python code.

## Overview

This project provides `.proto` definitions equivalent to the C++ models found in the EpochFolio `src/models/` directory. The protobuf definitions generate code for:

- **C++**: Static library with headers for integration
- **Python**: Python modules with type stubs (`.pyi`) for IDE support
- **TypeScript**: TypeScript definitions for web applications

## Generated Models

### Common Types (`common.proto`)
- **Enums**: 
  - `EpochFolioCategory`: Strategy analysis categories (StrategyBenchmark, RiskAnalysis, etc.)
  - `EpochFolioDashboardWidget`: Widget types (Lines, Bar, DataTable, HeatMap, etc.)  
  - `EpochFolioType`: Data types (String, Integer, Decimal, Percent, Boolean, etc.)
  - `AxisType`: Chart axis types (Linear, Logarithmic, DateTime, Category)
- **Messages**:
  - `Scalar`: Generic value container supporting multiple data types
  - `Array`: Collection of scalar values

### Chart Definitions (`chart_def.proto`)
- `ChartDef`: Base chart configuration
- `AxisDef`: Chart axis configuration
- `LinesDef`: Line chart with series data
- `BarDef`: Bar chart definition
- `HeatMapDef`: Heat map chart
- `HistogramDef`: Histogram chart
- `BoxPlotDef`: Box plot chart
- `XRangeDef`: Range chart for time series
- `PieDef`: Pie chart definition
- Supporting types: `Point`, `Line`, `Band`, `StraightLineDef`, etc.

### Table Definitions (`table_def.proto`)
- `Table`: Data table with schema and data
- `CardDef`: Dashboard card widget
- `ColumnDef`: Table column definition
- `CategoryDef`: Category with sub-categories
- `TableData` & `TableRow`: Table data representation

## Building

### Using vcpkg (Recommended)

#### Prerequisites
```bash
# Install vcpkg if you haven't already
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh
export VCPKG_ROOT=$(pwd)
```

#### Install as vcpkg Package
```bash
# Install from vcpkg registry (when published)
vcpkg install epoch-protos

# Or install from local port
vcpkg install epoch-protos --overlay-ports=/path/to/EpochProtos/ports
```

#### Use in CMake Projects with vcpkg
```cmake
# In your CMakeLists.txt
find_package(EpochProtos CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE EpochProtos::epoch_protos_cpp)
```

#### Build with vcpkg Toolchain
```bash
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build .
```

### Manual Build (Alternative)

#### Prerequisites
```bash
# Install protobuf compiler
sudo apt install protobuf-compiler libprotobuf-dev

# For TypeScript generation (optional)
npm install -g protoc-gen-ts

# For Python support
sudo apt install python3-protobuf
```

#### Build All Languages
```bash
mkdir build && cd build
cmake ..
make generate_all_protos
```

#### Individual Language Targets
```bash
# C++ only
make epoch_protos_cpp

# Python only  
make generate_python_protos

# TypeScript only
make generate_typescript_protos
```

#### Build Options
```bash
# Disable Python/TypeScript generation for vcpkg-style builds
cmake .. -DBUILD_PYTHON_PROTOS=OFF -DBUILD_TYPESCRIPT_PROTOS=OFF

# Disable proto file installation
cmake .. -DINSTALL_PROTO_FILES=OFF
```

## Generated Output Structure

```
build/generated/
├── cpp/
│   └── libepoch_protos_cpp.a    # Static library
├── python/
│   ├── common_pb2.py            # Generated Python modules
│   ├── chart_def_pb2.py
│   ├── table_def_pb2.py
│   ├── *.pyi                    # Type stubs
│   └── setup.py                 # Package setup
└── typescript/
    ├── common.ts                # Generated TypeScript
    ├── chart_def.ts
    ├── table_def.ts
    └── package.json             # NPM package config
```

## Usage Examples

### C++
```cpp
#include "common.pb.h"
#include "chart_def.pb.h"

epoch_folio::ChartDef chart;
chart.set_id("my_chart");
chart.set_title("Portfolio Returns");
chart.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_LINES);
chart.set_category(epoch_folio::EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);
```

### Python
```python
import common_pb2
import chart_def_pb2

chart = chart_def_pb2.ChartDef()
chart.id = "my_chart"
chart.title = "Portfolio Returns"
chart.type = common_pb2.EPOCH_FOLIO_DASHBOARD_WIDGET_LINES
chart.category = common_pb2.EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK
```

### TypeScript
```typescript
import { ChartDef, EpochFolioDashboardWidget, EpochFolioCategory } from './chart_def';

const chart = new ChartDef();
chart.setId("my_chart");
chart.setTitle("Portfolio Returns");
chart.setType(EpochFolioDashboardWidget.EPOCH_FOLIO_DASHBOARD_WIDGET_LINES);
chart.setCategory(EpochFolioCategory.EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);
```

## Testing

Test files are provided in the `test/` directory:

```bash
# Test C++ 
cd test
g++ -std=c++20 -I../build -o test_cpp test_cpp.cpp ../build/generated/cpp/libepoch_protos_cpp.a -lprotobuf
./test_cpp

# Test Python
python3 test_python.py
```

## Integration

### C++ Projects

#### With vcpkg
```cmake
# vcpkg.json in your project root
{
  "dependencies": ["epoch-protos"]
}

# In your CMakeLists.txt
find_package(EpochProtos CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE EpochProtos::epoch_protos_cpp)
```

#### Manual Integration
```cmake
find_package(EpochProtos REQUIRED)
target_link_libraries(your_target epoch_protos_cpp)
```

### Python Projects
```bash
cd build/generated/python
pip install .
```

### TypeScript/JavaScript Projects
```bash
cd build/generated/typescript
npm install
npm run build
```

## vcpkg Distribution

### Publishing to vcpkg Registry

To publish this package to the vcpkg registry:

1. **Fork the vcpkg repository**
2. **Add the port files** from `ports/epoch-protos/` to `vcpkg/ports/epoch-protos/`
3. **Update the SHA512** in `portfile.cmake` with the actual release archive hash
4. **Test the port**:
   ```bash
   vcpkg install epoch-protos --overlay-ports=./ports
   ```
5. **Submit a pull request** to the vcpkg repository

### Local vcpkg Usage

For development and testing:

```bash
# Install from local overlay
vcpkg install epoch-protos --overlay-ports=/path/to/EpochProtos/ports

# Use in your project
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build
```

### vcpkg Features

The package supports these vcpkg features:

- **`tools`**: Include protobuf compiler tools for custom code generation
- Default: C++ library only for minimal dependencies

## Mapping from Original C++ Models

| C++ Model | Proto Equivalent | Description |
|-----------|------------------|-------------|
| `chart_def.h::ChartDef` | `chart_def.proto::ChartDef` | Base chart configuration |
| `chart_def.h::LinesDef` | `chart_def.proto::LinesDef` | Line chart definition |
| `chart_def.h::BarDef` | `chart_def.proto::BarDef` | Bar chart definition |
| `chart_def.h::Point` | `chart_def.proto::Point` | Chart data point |
| `table_def.h::Table` | `table_def.proto::Table` | Data table |
| `table_def.h::CardDef` | `table_def.proto::CardDef` | Dashboard card |
| `epoch_frame::Scalar` | `common.proto::Scalar` | Generic value type |

## Notes

- All enums use the UPPER_CASE naming convention required by protobuf
- Optional fields in C++ are represented as `optional` in proto3
- The `epoch_frame::Array` type is mapped to `repeated Scalar` in protobuf
- Arrow table data is flattened to a simpler row/column structure in protobuf
- Complex C++ types like `std::variant` are represented as `oneof` in protobuf