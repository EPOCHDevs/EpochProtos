#include "../build/chart_def.pb.h"
#include "../build/common.pb.h"
#include "../build/table_def.pb.h"
#include <iostream>
#include <memory>

int main() {
  // Test Scalar creation
  epoch_folio::Scalar scalar;
  scalar.set_double_value(42.5);

  std::cout << "Scalar double value: " << scalar.double_value() << std::endl;

  // Test ChartDef creation
  epoch_folio::ChartDef chart;
  chart.set_id("test_chart");
  chart.set_title("Test Chart");
  chart.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_LINES);
  chart.set_category(epoch_folio::EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);

  std::cout << "Chart ID: " << chart.id() << std::endl;
  std::cout << "Chart Title: " << chart.title() << std::endl;
  std::cout << "Chart Type: " << chart.type() << std::endl;
  std::cout << "Chart Category: " << chart.category() << std::endl;

  // Test Point creation
  epoch_folio::Point point;
  point.mutable_x()->set_double_value(1.0);
  point.mutable_y()->set_double_value(2.0);

  std::cout << "Point X: " << point.x().double_value() << std::endl;
  std::cout << "Point Y: " << point.y().double_value() << std::endl;

  // Test Line creation
  epoch_folio::Line line;
  line.set_name("Test Line");
  line.add_data()->CopyFrom(point);

  std::cout << "Line name: " << line.name() << std::endl;
  std::cout << "Line data points: " << line.data_size() << std::endl;

  // Test Table creation
  epoch_folio::Table table;
  table.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_DATA_TABLE);
  table.set_category(epoch_folio::EPOCH_FOLIO_CATEGORY_POSITIONS);
  table.set_title("Test Table");

  // Add column definition
  auto *column = table.add_columns();
  column->set_id("col1");
  column->set_name("Column 1");
  column->set_type(epoch_folio::EPOCH_FOLIO_TYPE_STRING);

  std::cout << "Table title: " << table.title() << std::endl;
  std::cout << "Table columns: " << table.columns_size() << std::endl;
  std::cout << "First column name: " << table.columns(0).name() << std::endl;

  std::cout << "All tests passed!" << std::endl;
  return 0;
}
