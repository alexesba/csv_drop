# frozen_string_literal: true

class FakeRedis
  def initialize
    @data = {}
    @expiry = {}
  end

  def setex(key, ttl, value)
    @data[key] = value
    @expiry[key] = Process.clock_gettime(Process::CLOCK_MONOTONIC) + ttl
    "OK"
  end

  def get(key)
    expire!(key)
    @data[key]
  end

  def del(key)
    @data.delete(key)
    @expiry.delete(key)
    1
  end

  private

  def expire!(key)
    return unless @expiry[key]
    return unless Process.clock_gettime(Process::CLOCK_MONOTONIC) >= @expiry[key]

    del(key)
  end
end
