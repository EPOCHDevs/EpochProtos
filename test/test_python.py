#!/usr/bin/env python3
"""
Test script to verify the generated Python protobuf code works correctly.
"""
import sys
import os

# Add the generated Python directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../build/generated/python'))

try:
    import epoch_protos.common_pb2 as common_pb2
    import epoch_protos.chart_def_pb2 as chart_def_pb2
    import epoch_protos.table_def_pb2 as table_def_pb2
    
    print("Successfully imported all protobuf modules!")
    
    # Test Scalar creation
    scalar = common_pb2.Scalar()
    scalar.decimal_value = 42.5
    print(f"Scalar decimal value: {scalar.decimal_value}")
    
    # Test ChartDef creation
    chart = chart_def_pb2.ChartDef()
    chart.id = "test_chart"
    chart.title = "Test Chart"
    chart.type = 2  # WidgetLines
    chart.category = "test_category"
    
    print(f"Chart ID: {chart.id}")
    print(f"Chart Title: {chart.title}")
    print(f"Chart Type: {chart.type}")
    print(f"Chart Category: {chart.category}")
    
    # Test Point creation
    point = chart_def_pb2.Point()
    point.x = 1000  # timestamp in milliseconds
    point.y = 2.0   # numeric value
    
    print(f"Point X: {point.x}")
    print(f"Point Y: {point.y}")
    
    # Test Line creation
    line = chart_def_pb2.Line()
    line.name = "Test Line"
    line.data.append(point)
    
    print(f"Line name: {line.name}")
    print(f"Line data points: {len(line.data)}")
    
    # Test Table creation
    table = table_def_pb2.Table()
    table.type = 4  # WidgetDataTable
    table.category = "test_category"
    table.title = "Test Table"
    
    # Add column definition
    column = table.columns.add()
    column.id = "col1"
    column.name = "Column 1"
    column.type = 1  # TypeString
    
    print(f"Table title: {table.title}")
    print(f"Table columns: {len(table.columns)}")
    print(f"First column name: {table.columns[0].name}")
    
    # Test enum values
    print(f"\nTesting enum values:")
    print(f"TypeString: 1")
    print(f"TypeDecimal: 3")
    print(f"LINES widget: 2")
    print(f"BAR widget: 3")
    
    print("\nAll Python tests passed!")
    
except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Test error: {e}")
    sys.exit(1)
