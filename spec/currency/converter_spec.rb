# frozen_string_literal: true

RSpec.describe Currency::Converter do
  it "has a version number" do
    expect(Currency::Converter::VERSION).not_to be nil
  end

  describe ".new" do
    let(:remote_client) do
      double("client")
    end

    it "expects remote client to implement #fetch" do
      expect { described_class.new(client: remote_client) }.to raise_error(described_class::IncompatibleClient)
      allow(remote_client).to receive(:fetch)
      expect { described_class.new(client: remote_client) }.not_to raise_error
    end
  end

  describe "#convert" do
    subject { described_class.new(client: remote_client) }

    let(:remote_client) { double("client", fetch: conversion_rates) }
    let(:conversion_rates) { {"usd" => 3, "pln" => 2.3412} }

    context "when conversion is known" do
      it "correctly converts the amount" do
        amount = "32"
        expect(subject.convert(amount, from: "JPY", to: "PLN")).to eq(BigDecimal(amount) * conversion_rates["pln"])
      end
    end

    context "when conversion is not known" do
      it "raises error" do
        amount = "32"
        expect { subject.convert(amount, from: "JPY", to: "BYN") }.to raise_error(described_class::UnknownRate).with_message("Couldn't discover conversion rate from JPY to BYN")
      end
    end
  end

  describe "e2e" do
    subject { described_class.new(client: Currency::Api::Exchangerate.new(Currency::Api::Adapters::HTTPX.new, url: "http://127.0.0.1:3001#{path}/")) }

    let(:pln_rate) { BigDecimal("2.03") }
    let(:raw_modified) do
      <<~JSON
        {"result":"success","provider":"https://www.exchangerate-api.com","documentation":"https://www.exchangerate-api.com/docs/free","terms_of_use":"https://www.exchangerate-api.com/terms","time_last_update_unix":1682726552,"time_last_update_utc":"Sat, 29 Apr 2023 00:02:32 +0000","time_next_update_unix":1682814142,"time_next_update_utc":"Sun, 30 Apr 2023 00:22:22 +0000","time_eol_unix":0,"base_code":"USD","rates":{"USD":1,"AED":3.6725,"AFN":86.317048,"ALL":100.642308,"AMD":386.526721,"ANG":1.79,"AOA":512.681726,"ARS":221.09848,"AUD":1.512261,"AWG":1.79,"AZN":1.70011,"BAM":1.775769,"BBD":2,"BDT":107.10523,"BGN":1.776345,"BHD":0.376,"BIF":2073.123424,"BMD":1,"BND":1.335338,"BOB":6.924618,"BRL":4.991606,"BSD":1,"BTN":81.818558,"BWP":13.219082,"BYN":2.776171,"BZD":2,"CAD":1.357785,"CDF":2091.160361,"CHF":0.894502,"CLP":803.7078,"CNY":6.920434,"COP":4573.372213,"CRC":533.715547,"CUP":24,"CVE":100.113569,"CZK":21.349526,"DJF":177.721,"DKK":6.773548,"DOP":54.634772,"DZD":135.283133,"EGP":30.908333,"ERN":15,"ETB":54.435188,"EUR":0.907923,"FJD":2.224594,"FKP":0.798081,"FOK":6.773548,"GBP":0.798093,"GEL":2.49797,"GGP":0.798081,"GHS":11.854523,"GIP":0.798081,"GMD":62.519641,"GNF":8543.069215,"GTQ":7.799839,"GYD":211.488502,"HKD":7.849576,"HNL":24.577377,"HRK":6.840844,"HTG":153.652034,"HUF":338.357264,"IDR":14650.204804,"ILS":3.631046,"IMP":0.798081,"INR":81.818579,"IQD":1308.641558,"IRR":42017.799496,"ISK":135.719442,"JEP":0.798081,"JMD":153.359576,"JOD":0.709,"JPY":136.136237,"KES":135.90601,"KGS":87.637924,"KHR":4120.155809,"KID":1.512247,"KMF":446.675257,"KRW":1337.866307,"KWD":0.306346,"KYD":0.833333,"KZT":452.395369,"LAK":17094.950417,"LBP":15000,"LKR":321.614366,"LRD":163.959663,"LSL":18.300015,"LYD":4.763836,"MAD":10.056078,"MDL":17.97146,"MGA":4402.497933,"MKD":55.76974,"MMK":2097.170022,"MNT":3509.930542,"MOP":8.085046,"MRU":34.31116,"MUR":44.850391,"MVR":15.434747,"MWK":1033.01087,"MXN":18.012823,"MYR":4.459472,"MZN":63.96039,"NAD":18.300015,"NGN":460.59487,"NIO":36.564247,"NOK":10.668454,"NPR":130.909693,"NZD":1.621882,"OMR":0.384497,"PAB":1,"PEN":3.715582,"PGK":3.536763,"PHP":55.439156,"PKR":282.277457,"PLN":#{pln_rate},"PYG":7238.32948,"QAR":3.64,"RON":4.487701,"RSD":106.224149,"RUB":80.110133,"RWF":1160.036659,"SAR":3.75,"SBD":8.295227,"SCR":13.214313,"SDG":562.995128,"SEK":10.282138,"SGD":1.335339,"SHP":0.798081,"SLE":22.811749,"SLL":22811.749301,"SOS":568.671402,"SRD":36.848284,"SSP":877.967828,"STN":22.244433,"SYP":2488.485531,"SZL":18.300015,"THB":34.1096,"TJS":10.875818,"TMT":3.499945,"TND":3.036715,"TOP":2.335388,"TRY":19.460845,"TTD":6.740925,"TVD":1.512247,"TWD":30.708296,"TZS":2352.996373,"UAH":36.926712,"UGX":3746.730152,"UYU":38.820409,"UZS":11384.11277,"VES":24.7503,"VND":23484.660326,"VUV":118.663041,"WST":2.727571,"XAF":595.56701,"XCD":2.7,"XDR":0.742258,"XOF":595.56701,"XPF":108.345825,"YER":250.183985,"ZAR":18.299137,"ZMW":17.736415,"ZWL":1037.80503}}
      JSON
    end
    let(:from) { "USD" }
    let(:path) { RSpec.configuration.web_server.mount_echo(raw_modified, suffix: from) }

    after { RSpec.configuration.web_server.umount(path, suffix: from) }

    it "fetches and uses remote data" do
      expect(subject.convert(10, from: from, to: :PLN)).to eq(pln_rate * 10)
    end
  end
end
