require 'spec_helper'

describe 'selinux::module' do
  mymodule = 'mymodule'
  let(:title) { mymodule }
  include_context 'RedHat 7'

  context 'present case' do
    let(:params) do
      {
        source: "puppet:///modules/#{mymodule}/selinux"
      }
    end

    it do
      should contain_file("/usr/share/selinux/#{mymodule}").with(ensure: 'directory')

      should contain_file("/usr/share/selinux/#{mymodule}/#{mymodule}.te").that_notifies("Exec[/usr/share/selinux/#{mymodule}/#{mymodule}.pp]")

      should contain_exec("/usr/share/selinux/#{mymodule}/#{mymodule}.pp").with(command: 'make -f /usr/share/selinux/devel/Makefile')

      should contain_selmodule(mymodule).with_ensure('present')
    end
  end  # context

  context 'absent case' do
    let(:params) do
      {
        ensure: 'absent'
      }
    end

    it do
      should contain_file("/usr/share/selinux/#{mymodule}").with(ensure: 'absent')
      should contain_selmodule(mymodule).with_ensure('absent')
    end
  end  # context
end # describe
