Configuration UbuntuDefaultRepositories
{
    Import-DscResource -ModuleName 'nx'

    Node "localhost"
    {
        nxFile SourcesList
        {
            DestinationPath = "/etc/apt/sources.list"
            Contents = @"
                        # Ubuntu 22.04 LTS (Jammy Jellyfish) - Official Repositories

                        # Main repository - Officially supported free and open-source software
                        deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
                        deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse

                        # Updates - Important security updates
                        deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
                        deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse

                        # Security updates
                        deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
                        deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

                        # Backports - Unsupported updates to newer versions
                        deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
                        deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
                        "@
            Ensure = "Present"
            Type = "File"
            Force = $true
        }

        nxScript UpdateAptCache
        {
            GetScript = @"
#!/bin/bash
echo "Checking apt cache status"
"@
            SetScript = @"
#!/bin/bash
apt-get update
"@
            TestScript = @"
#!/bin/bash
exit 1
"@
            DependsOn = "[nxFile]SourcesList"
        }
    }
}

# Generate the MOF file
UbuntuDefaultRepositories -OutputPath "./"