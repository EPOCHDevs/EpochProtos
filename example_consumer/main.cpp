#include <epoch_protos/chart_def.pb.h>
#include <epoch_protos/common.pb.h>
#include <epoch_protos/table_def.pb.h>
#include <iostream>

int main() {
  std::cout << "EpochProtos Consumer Example\n";
  std::cout << "============================\n\n";

  // Create a portfolio chart
  epoch_folio::ChartDef portfolio_chart;
  portfolio_chart.set_id("portfolio_performance");
  portfolio_chart.set_title("Portfolio Performance vs Benchmark");
  portfolio_chart.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_LINES);
  portfolio_chart.set_category(
      epoch_folio::EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);

  // Set up axes
  auto *y_axis = portfolio_chart.mutable_y_axis();
  y_axis->set_type(epoch_folio::AXIS_TYPE_LINEAR);
  y_axis->set_label("Returns (%)");

  auto *x_axis = portfolio_chart.mutable_x_axis();
  x_axis->set_type(epoch_folio::AXIS_TYPE_DATETIME);
  x_axis->set_label("Date");

  std::cout << "Created Chart: " << portfolio_chart.title() << "\n";
  std::cout << "Chart ID: " << portfolio_chart.id() << "\n";
  std::cout << "Widget Type: " << portfolio_chart.type() << "\n";
  std::cout << "Category: " << portfolio_chart.category() << "\n\n";

  // Create sample data points
  epoch_folio::LinesDef lines_chart;
  lines_chart.mutable_chart_def()->CopyFrom(portfolio_chart);

  // Add portfolio performance line
  auto *portfolio_line = lines_chart.add_lines();
  portfolio_line->set_name("Portfolio");

  // Add some sample data points
  for (int i = 0; i < 5; ++i) {
    auto *point = portfolio_line->add_data();
    point->mutable_x()->set_decimal_value(i * 30.0); // Days
    point->mutable_y()->set_decimal_value(i * 2.5 +
                                          (i % 2 ? 1.0 : -0.5)); // Returns
  }

  // Add benchmark line
  auto *benchmark_line = lines_chart.add_lines();
  benchmark_line->set_name("S&P 500");

  for (int i = 0; i < 5; ++i) {
    auto *point = benchmark_line->add_data();
    point->mutable_x()->set_decimal_value(i * 30.0);
    point->mutable_y()->set_decimal_value(i * 1.8 + (i % 2 ? 0.5 : -0.2));
  }

  std::cout << "Lines Chart Data:\n";
  std::cout << "- " << lines_chart.lines(0).name() << ": "
            << lines_chart.lines(0).data_size() << " points\n";
  std::cout << "- " << lines_chart.lines(1).name() << ": "
            << lines_chart.lines(1).data_size() << " points\n\n";

  // Create a summary table
  epoch_folio::Table summary_table;
  summary_table.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_DATA_TABLE);
  summary_table.set_category(
      epoch_folio::EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);
  summary_table.set_title("Performance Summary");

  // Define columns
  auto *metric_col = summary_table.add_columns();
  metric_col->set_id("metric");
  metric_col->set_name("Metric");
  metric_col->set_type(epoch_folio::EPOCH_FOLIO_TYPE_STRING);

  auto *portfolio_col = summary_table.add_columns();
  portfolio_col->set_id("portfolio");
  portfolio_col->set_name("Portfolio");
  portfolio_col->set_type(epoch_folio::EPOCH_FOLIO_TYPE_PERCENT);

  auto *benchmark_col = summary_table.add_columns();
  benchmark_col->set_id("benchmark");
  benchmark_col->set_name("Benchmark");
  benchmark_col->set_type(epoch_folio::EPOCH_FOLIO_TYPE_PERCENT);

  // Add sample data
  auto *table_data = summary_table.mutable_data();

  // Add schema to table data
  for (const auto &col : summary_table.columns()) {
    table_data->add_schema()->CopyFrom(col);
  }

  // Add rows
  auto *row1 = table_data->add_rows();
  row1->add_values()->set_string_value("Total Return");
  row1->add_values()->set_decimal_value(12.5);
  row1->add_values()->set_decimal_value(9.8);

  auto *row2 = table_data->add_rows();
  row2->add_values()->set_string_value("Volatility");
  row2->add_values()->set_decimal_value(15.2);
  row2->add_values()->set_decimal_value(16.1);

  std::cout << "Summary Table: " << summary_table.title() << "\n";
  std::cout << "Columns: " << summary_table.columns_size() << "\n";
  std::cout << "Rows: " << summary_table.data().rows_size() << "\n\n";

  // Create dashboard cards
  epoch_folio::CardDef performance_cards;
  performance_cards.set_type(epoch_folio::EPOCH_FOLIO_DASHBOARD_WIDGET_CARD);
  performance_cards.set_category(
      epoch_folio::EPOCH_FOLIO_CATEGORY_STRATEGY_BENCHMARK);
  performance_cards.set_group_size(2);

  // Add cards
  auto *return_card = performance_cards.add_data();
  return_card->set_title("Total Return");
  return_card->mutable_value()->set_percent_value(12.5);
  return_card->set_type(epoch_folio::EPOCH_FOLIO_TYPE_PERCENT);
  return_card->set_group(0);

  auto *sharpe_card = performance_cards.add_data();
  sharpe_card->set_title("Sharpe Ratio");
  sharpe_card->mutable_value()->set_decimal_value(1.42);
  sharpe_card->set_type(epoch_folio::EPOCH_FOLIO_TYPE_DECIMAL);
  sharpe_card->set_group(0);

  std::cout << "Performance Cards:\n";
  for (const auto &card : performance_cards.data()) {
    std::cout << "- " << card.title() << ": ";
    if (card.value().has_decimal_value()) {
      std::cout << card.value().decimal_value();
    } else if (card.value().has_percent_value()) {
      std::cout << card.value().percent_value();
    }
    std::cout << " (group " << card.group() << ")\n";
  }

  std::cout << "\n✅ EpochProtos integration successful!\n";
  std::cout << "All protobuf models created and populated correctly.\n";

  return 0;
}
