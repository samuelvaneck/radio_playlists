# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PeriodParser do
  describe '.parse_duration' do
    context 'with granular periods' do
      it 'parses hour periods', :aggregate_failures do
        expect(described_class.parse_duration('1_hour')).to eq(1.hour)
        expect(described_class.parse_duration('2_hours')).to eq(2.hours)
      end

      it 'parses day periods', :aggregate_failures do
        expect(described_class.parse_duration('1_day')).to eq(1.day)
        expect(described_class.parse_duration('3_days')).to eq(3.days)
        expect(described_class.parse_duration('7_days')).to eq(7.days)
      end

      it 'parses week periods', :aggregate_failures do
        expect(described_class.parse_duration('1_week')).to eq(1.week)
        expect(described_class.parse_duration('2_weeks')).to eq(2.weeks)
        expect(described_class.parse_duration('4_weeks')).to eq(4.weeks)
      end

      it 'parses month periods', :aggregate_failures do
        expect(described_class.parse_duration('1_month')).to eq(1.month)
        expect(described_class.parse_duration('6_months')).to eq(6.months)
        expect(described_class.parse_duration('12_months')).to eq(12.months)
      end

      it 'parses year periods', :aggregate_failures do
        expect(described_class.parse_duration('1_year')).to eq(1.year)
        expect(described_class.parse_duration('2_years')).to eq(2.years)
      end
    end

    context 'with legacy periods' do
      it 'normalizes legacy period names', :aggregate_failures do
        expect(described_class.parse_duration('hour')).to eq(1.hour)
        expect(described_class.parse_duration('week')).to eq(1.week)
        expect(described_class.parse_duration('month')).to eq(1.month)
        expect(described_class.parse_duration('year')).to eq(1.year)
      end
    end

    context 'with all period' do
      it 'returns nil' do
        expect(described_class.parse_duration('all')).to be_nil
      end
    end

    context 'with invalid periods' do
      it 'returns nil', :aggregate_failures do
        expect(described_class.parse_duration('invalid')).to be_nil
        expect(described_class.parse_duration('3_bananas')).to be_nil
        expect(described_class.parse_duration('')).to be_nil
      end
    end
  end

  describe '.aggregation_for' do
    it 'returns minute-level aggregation for hour periods', :aggregate_failures do
      result = described_class.aggregation_for('2_hours')
      expect(result[:strftime]).to eq('%Y-%m-%dT%H:%M')
      expect(result[:time_step]).to eq(10.minutes)
    end

    it 'returns hourly aggregation for day periods', :aggregate_failures do
      result = described_class.aggregation_for('3_days')
      expect(result[:strftime]).to eq('%Y-%m-%dT%H:00')
      expect(result[:time_step]).to eq(1.hour)
    end

    it 'returns daily aggregation for week periods', :aggregate_failures do
      result = described_class.aggregation_for('2_weeks')
      expect(result[:strftime]).to eq('%Y-%m-%d')
      expect(result[:time_step]).to eq(1.day)
    end

    it 'returns daily aggregation for month periods', :aggregate_failures do
      result = described_class.aggregation_for('6_months')
      expect(result[:strftime]).to eq('%Y-%m-%d')
      expect(result[:time_step]).to eq(1.day)
    end

    it 'returns monthly aggregation for year periods', :aggregate_failures do
      result = described_class.aggregation_for('1_year')
      expect(result[:strftime]).to eq('%Y-%m-01')
      expect(result[:time_step]).to eq(1.month)
    end

    it 'returns monthly aggregation for all', :aggregate_failures do
      result = described_class.aggregation_for('all')
      expect(result[:strftime]).to eq('%Y-%m-01')
      expect(result[:time_step]).to eq(1.month)
    end

    it 'handles legacy period names', :aggregate_failures do
      expect(described_class.aggregation_for('hour')[:time_step]).to eq(10.minutes)
      expect(described_class.aggregation_for('week')[:time_step]).to eq(1.day)
      expect(described_class.aggregation_for('month')[:time_step]).to eq(1.day)
      expect(described_class.aggregation_for('year')[:time_step]).to eq(1.month)
    end
  end
end
