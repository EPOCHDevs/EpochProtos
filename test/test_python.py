#!/usr/bin/env python3
"""
Test script to verify the generated Python protobuf code works correctly.
"""
import sys
import os

# Add the generated Python directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../build/generated/python'))

try:
    import common_pb2
    import chart_def_pb2
    import table_def_pb2
    
    print("Successfully imported all protobuf modules!")
    
    # Test Scalar creation
    scalar = common_pb2.Scalar()
    scalar.double_value = 42.5
    print(f"Scalar double value: {scalar.double_value}")
    
    # Test ChartDef creation
    chart = chart_def_pb2.ChartDef()
    chart.id = "test_chart"
    chart.title = "Test Chart"
    chart.type = common_pb2.EPOCH_FOLIO_DASHBOARD_WIDGET_LINES
    chart.category = common_pb2.EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK
    
    print(f"Chart ID: {chart.id}")
    print(f"Chart Title: {chart.title}")
    print(f"Chart Type: {chart.type}")
    print(f"Chart Category: {chart.category}")
    
    # Test Point creation
    point = chart_def_pb2.Point()
    point.x.double_value = 1.0
    point.y.double_value = 2.0
    
    print(f"Point X: {point.x.double_value}")
    print(f"Point Y: {point.y.double_value}")
    
    # Test Line creation
    line = chart_def_pb2.Line()
    line.name = "Test Line"
    line.data.append(point)
    
    print(f"Line name: {line.name}")
    print(f"Line data points: {len(line.data)}")
    
    # Test Table creation
    table = table_def_pb2.Table()
    table.type = common_pb2.EPOCH_FOLIO_DASHBOARD_WIDGET_DATA_TABLE
    table.category = common_pb2.EPOCH_FOLIO_CATEGORY_POSITIONS
    table.title = "Test Table"
    
    # Add column definition
    column = table.columns.add()
    column.id = "col1"
    column.name = "Column 1"
    column.type = common_pb2.EPOCH_FOLIO_TYPE_STRING
    
    print(f"Table title: {table.title}")
    print(f"Table columns: {len(table.columns)}")
    print(f"First column name: {table.columns[0].name}")
    
    # Test enum values
    print(f"\nTesting enum values:")
    print(f"STRATEGY_BENCHMARK: {common_pb2.EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK}")
    print(f"RISK_ANALYSIS: {common_pb2.EPOCH_FOLIO_CATEGORY_RISK_ANALYSIS}")
    print(f"LINES widget: {common_pb2.EPOCH_FOLIO_DASHBOARD_WIDGET_LINES}")
    print(f"BAR widget: {common_pb2.EPOCH_FOLIO_DASHBOARD_WIDGET_BAR}")
    
    print("\nAll Python tests passed!")
    
except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Test error: {e}")
    sys.exit(1)
