#!/bin/bash

PYTHON_VERSION="python2.5"

TEMP_DIR="/tmp/djangoappengine_bootstrap"
DOWNLOAD_DIR="/tmp/djangoappengine_bootstrap_downloads"

WGET="wget -q -c"

test() {
    # Python 2.5
    if [ -z $(which $PYTHON_VERSION) ]; then
        echo "No $PYTHON_VERSION version found."
        if [[ $(lsb_release -c | awk '{print $2}') = 'natty' ]]; then
            # http://dewbot.posterous.com/installation-of-python-25-and-google-app-engi
            echo "You might install from a ppa-repository."
            echo -n "Would you like to install? [y/N] "
            read q1

            if [[ "$q1" = 'y' ]] || [[ $q1 = 'Y' ]]; then
                echo "Adding ppa-repository..."
                sudo add-apt-repository ppa:fkrull/deadsnakes >/dev/null 2>&1
                echo "Updating..."
                sudo apt-get -qq update
                echo "Downloading..."
                sudo apt-get -qq -y install $PYTHON_VERSION
            else
                echo "Bye."
                exit
            fi
        fi
    fi

    echo
}

download() {
    echo "Downloading (may take a while)..."
    mkdir -p $DOWNLOAD_DIR

    while read line
    do
        $WGET $line
        mv *.tar.gz $DOWNLOAD_DIR
    done < "download.list"

    echo
}

extract() {
    echo "Extracting..."
    cd $DOWNLOAD_DIR

    for f in *.tar.gz
    do
        echo $f
        tar zxmf $f
    done

    echo
}

copy() {
    echo "Copying..."
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR

    echo "django-testapp"
    cp -a $DOWNLOAD_DIR/wkornewald-django-testapp-*/* $TEMP_DIR

    echo "django-nonrel"
    cp -a $DOWNLOAD_DIR/wkornewald-django-nonrel-*/django $TEMP_DIR

    echo "djangoappengine"
    mkdir -p $TEMP_DIR/djangoappengine
    cp -a $DOWNLOAD_DIR/wkornewald-djangoappengine-*/* $TEMP_DIR/djangoappengine

    echo "djangotoolbox"
    cp -a $DOWNLOAD_DIR/wkornewald-djangotoolbox-*/djangotoolbox $TEMP_DIR

    echo "django-dbindexer"
    cp -a $DOWNLOAD_DIR/wkornewald-django-dbindexer-*/dbindexer $TEMP_DIR

    echo "django-autoload"
    cp -a $DOWNLOAD_DIR/twanschik-django-autoload-*/autoload $TEMP_DIR

    echo "nonrel-search"
    cp -a $DOWNLOAD_DIR/twanschik-nonrel-search-*/search $TEMP_DIR

    echo "django-permission-backend-nonrel"
    cp -a $DOWNLOAD_DIR/fhahn-django-permission-backend-nonrel-*/permission_backend_nonrel $TEMP_DIR

    echo "Done."
}

setup() {
    echo -n "What is the name of the project on Google App Engine? "
    read project

    echo -n "Where do you want to copy the new project? (ex.: /home/user/projects) "
    read workspace

    # Applying patches
    cat $PWD/admin/settings.py > $TEMP_DIR/settings.py
    cat $PWD/admin/urls.py > $TEMP_DIR/urls.py

    # Creating directories
    mkdir -p $workspace/$project
    cp -a $TEMP_DIR/* $workspace/$project
    cd $workspace/$project

    # Fixing app.yaml
    sed -i "s/ctst/$project/g" app.yaml
    echo -e '\n- url: /static\n  static_dir: static' >> app.yaml

    # Fixing manage.py
    sed -i "s/python/python2\.5/g" manage.py

    echo -n "Want to create a superuser? [y/N] "
    read q1
    if [[ "$q1" = 'y' ]] || [[ $q1 = 'Y' ]]; then
        python2.5 manage.py createsuperuser
        python2.5 manage.py syncdb
    fi

    echo -n "Want to deploy for Google App Engine? [y/N] "
    read q2
    if [[ "$q2" = 'y' ]] || [[ $q2 = 'Y' ]]; then
        appcfg.py update_indexes .
        python2.5 manage.py deploy

        echo -n "Want to create a remote superuser? [y/N] "
        read q3
        if [[ "$q3" = 'y' ]] || [[ $q3 = 'Y' ]]; then
            python2.5 manage.py remote createsuperuser
        fi
    fi

    echo "Done."
}

clean() {
    rm -Rf $TEMP_DIR
    rm -Rf $DOWNLOAD_DIR
}

test
download
extract
copy
setup
clean
