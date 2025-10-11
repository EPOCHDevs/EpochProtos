#!/usr/bin/env python3
"""
Test script for the epoch-protos Python package
"""

def test_imports():
    """Test that all modules can be imported"""
    try:
        import epoch_protos.common_pb2 as common
        import epoch_protos.chart_def_pb2 as chart_def
        import epoch_protos.table_def_pb2 as table_def
        print("✅ All imports successful")
        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False

def test_basic_functionality():
    """Test basic protobuf functionality"""
    try:
        import epoch_protos.common_pb2 as common
        import epoch_protos.chart_def_pb2 as chart_def
        
        # Test scalar
        scalar = common.Scalar()
        scalar.decimal_value = 123.45
        assert scalar.decimal_value == 123.45
        
        # Test chart
        chart = chart_def.ChartDef()
        chart.id = "test"
        chart.title = "Test Chart"
        chart.type = common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetBar'].number
        assert chart.id == "test"
        assert chart.title == "Test Chart"
        
        # Test serialization
        data = chart.SerializeToString()
        chart2 = chart_def.ChartDef()
        chart2.ParseFromString(data)
        assert chart2.id == chart.id
        assert chart2.title == chart.title
        
        print("✅ Basic functionality test passed")
        return True
    except Exception as e:
        print(f"❌ Functionality test failed: {e}")
        return False

def test_enums():
    """Test enum values"""
    try:
        import epoch_protos.common_pb2 as common
        
        # Test widget enum
        assert common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetLines'].number == 2
        assert common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetBar'].number == 3
        
        print("✅ Enum test passed")
        return True
    except Exception as e:
        print(f"❌ Enum test failed: {e}")
        return False

if __name__ == "__main__":
    print("Testing epoch-protos Python package...")
    
    tests = [test_imports, test_basic_functionality, test_enums]
    passed = 0
    
    for test in tests:
        if test():
            passed += 1
    
    print(f"\nResults: {passed}/{len(tests)} tests passed")
    
    if passed == len(tests):
        print("🎉 All tests passed!")
        exit(0)
    else:
        print("💥 Some tests failed!")
        exit(1)
