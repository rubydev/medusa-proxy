require 'test_helper'

class BalancingProxyTest < Test::Unit::TestCase

  context "Balancing Proxy" do

    setup do
      class Medusa::Backend
        @list = nil; @pool = nil
      end
    end

    context "generally" do

      should "should raise error for unknown strategy" do
        assert_raise(ArgumentError) { Medusa::Backend.select(:asdf) }
      end

    end

    context "when selecting the backend and Redis is available" do

      setup do
        $redis.del "medusa>backends>deathrow"
        class Medusa::Backend
          def self.list
            @list ||= [
              {:url => "http://127.0.0.1:3000"},
              {:url => "http://127.0.0.2:3000"},
              {:url => "http://127.0.0.3:3000"}
            ].map { |backend| new backend }
          end
        end
      end

      teardown do
        $redis.del "medusa>backends>deathrow"
      end

      should "check the deathrow list" do
        # Add the 127.0.0.1 proxy to deathrow
        $redis.sadd "medusa>backends>deathrow", 'http://127.0.0.1:3000'

        5.times do
          assert '127.0.0.1' != Medusa::Backend.select.host, "Should not select 1, because it's on a deathrow"
        end
      end

    end

    context "when no strategy is passed" do
      should "use the :balanced strategy" do
        backend = Medusa::Backend.select
        assert_equal :balanced, Medusa::Backend.strategy
      end
    end

    context "when no strategy is configured and passed" do
      setup do
        Medusa::STRATEGY = nil
      end
      should "use the :balanced strategy" do
        backend = Medusa::Backend.select(Medusa::STRATEGY)
        assert_equal :balanced, Medusa::Backend.strategy
      end
    end

    context "when strategy is configured and passed, it" do
      setup do
        Medusa::STRATEGY = :roundrobin
      end
      should "be used" do
        backend = Medusa::Backend.select(Medusa::STRATEGY)
        assert_equal :roundrobin, Medusa::Backend.strategy
      end
    end

    context "when using the 'random' strategy" do

      setup do
        class Medusa::Backend
          def self.list
            @list ||= [
              {:url => "http://127.0.0.1:3000"},
              {:url => "http://127.0.0.2:3000"},
              {:url => "http://127.0.0.3:3000"}
            ].map { |backend| new backend }
          end
        end
      end

      should "should select random backend" do

        srand(0)
        assert_equal '127.0.0.1', Medusa::Backend.select(:random).host
      end

    end

    context "when using the 'roundrobin' strategy" do
      should "should select backends in rotating order" do
        class Medusa::Backend
          def self.list
            @list ||= [
              {:url => "http://127.0.0.1:3000", :load => 0},
              {:url => "http://127.0.0.2:3000", :load => 0},
              {:url => "http://127.0.0.3:3000", :load => 0}
            ].map { |backend| new backend }
          end
        end

        assert_equal '127.0.0.1', Medusa::Backend.select(:roundrobin).host
        assert_equal '127.0.0.2', Medusa::Backend.select(:roundrobin).host
        assert_equal '127.0.0.3', Medusa::Backend.select(:roundrobin).host
        assert_equal '127.0.0.1', Medusa::Backend.select(:roundrobin).host
      end
    end

    context "when using the 'balanced' strategy" do

      should "should select the first backend when all backends have the same load" do
        class Medusa::Backend
          def self.list
            @list ||= [
              {:url => "http://127.0.0.3:3000", :load => 0},
              {:url => "http://127.0.0.2:3000", :load => 0},
              {:url => "http://127.0.0.1:3000", :load => 0}
            ].map { |backend| new backend }
          end
        end

        assert_equal '127.0.0.3', Medusa::Backend.select.host
      end

      should "should select the least loaded backend" do
        class Medusa::Backend
          def self.list
            @list ||= [
              {:url => "http://127.0.0.3:3000", :load => 2},
              {:url => "http://127.0.0.2:3000", :load => 1},
              {:url => "http://127.0.0.1:3000", :load => 0}
            ].map { |backend| new backend }
          end
        end

        one = Medusa::Backend.select
        assert_equal '127.0.0.1', one.host
        assert_equal '127.0.0.1', Medusa::Backend.select.host
        assert_equal '127.0.0.2', Medusa::Backend.select.host
        assert_equal '127.0.0.3', Medusa::Backend.select.host
        assert_equal '127.0.0.1', Medusa::Backend.select.host
        assert_equal '127.0.0.2', Medusa::Backend.select.host

        Medusa::Callbacks.on_finish.call(one) # Finish request
        assert_equal '127.0.0.1', Medusa::Backend.select.host
      end

    end

  end

end
