# frozen_string_literal: true

module RuboCop
  module Cop
    module Airplays
      # Sidekiq defines `Sidekiq::Rails` (its Rails engine class). Inside a
      # reopened `module Sidekiq`, Ruby's constant lookup walks `Module.nesting`
      # before falling through to the top level, so an unqualified `Rails`
      # resolves to `Sidekiq::Rails` and `Rails.logger` raises NoMethodError at
      # runtime. Force the explicit `::Rails` to skip the Sidekiq scope.
      class RailsInSidekiqNamespace < Base
        MSG = 'Use `::Rails` inside `module Sidekiq`; bare `Rails` resolves to `Sidekiq::Rails` (no `.logger`).'

        extend AutoCorrector

        def on_const(node)
          return unless node.short_name == :Rails
          return if node.namespace&.cbase_type?
          return if node.namespace
          return unless inside_top_level_sidekiq_module?(node)

          add_offense(node) do |corrector|
            corrector.replace(node, '::Rails')
          end
        end

        private

        def inside_top_level_sidekiq_module?(node)
          module_ancestors = node.each_ancestor(:module).to_a
          return false if module_ancestors.empty?

          outermost = module_ancestors.last
          identifier = outermost.identifier
          identifier.short_name == :Sidekiq && identifier.namespace.nil?
        end
      end
    end
  end
end
