# From https://github.com/reactjs/react-rails/blob/master/lib/react/server_rendering/webpacker_manifest_container.rb

class ServerSideRendering::WebpackerManifestContainer
  begin
    MAJOR, MINOR, PATCH, _ = Bundler.locked_gems.specs.find { |gem_spec| gem_spec.name == 'webpacker' }.version.segments
  rescue
    MAJOR, MINOR, PATCH, _ = [0,0,0]
  end

  # This pattern matches the code that initializes the dev-server client.
  CLIENT_REQUIRE = %r{__webpack_require__\(.*webpack-dev-server\/client\/index\.js.*\n}

  def self.compatible?
    !!defined?(Webpacker)
  end

  if MAJOR < 3
    def find_asset(logical_path)
      # raises if not found
      asset_path = manifest.lookup(logical_path).to_s
      if asset_path.start_with?('http')
        # Get a file from the webpack-dev-server
        dev_server_asset = open(asset_path).read
        # Remove `webpack-dev-server/client/index.js` code which causes ExecJS to 💥
        dev_server_asset.sub!(CLIENT_REQUIRE, '//\0')
        dev_server_asset
      else
        # Read the already-compiled pack:
        full_path = file_path(logical_path).to_s
        File.read(full_path)
      end
    end
  else
    def find_asset(logical_path)
      asset_path = Webpacker.manifest.lookup(logical_path).to_s
      if Webpacker.dev_server.running?
        dev_server_asset = if asset_path.start_with?('http')
          open(asset_path).read
        else
          ds = Webpacker.dev_server
          open("#{ds.protocol}://#{ds.host_with_port}#{asset_path}").read
        end
        dev_server_asset.sub!(CLIENT_REQUIRE, '//\0')
        dev_server_asset
      else
        File.read(file_path(logical_path))
      end
    end
  end

  if MAJOR < 3
    def manifest
      Webpacker::Manifest
    end
  else
    def manifest
      Webpacker.manifest
    end
  end

  if MAJOR < 3
    def config
      Webpacker::Configuration
    end
  else
    def config
      Webpacker.config
    end
  end

  if (MAJOR == 1 && MINOR >= 2) || MAJOR == 2
    def file_path path
      manifest.lookup_path(path)
    end
  elsif MAJOR == 3
    def file_path path
      ::Rails.root.join('public', manifest.lookup(path)[1..-1])
    end
  else # 1.0 and 1.1 support
    def file_path path
      File.join(output_path, manifest.lookup(path).split('/')[2..-1])
    end
  end

  def output_path
    # Webpack1 /:output/:entry, Webpack3 /public/:output
    config.respond_to?(:output_path) ? config.output_path : 'public'
  end
end
