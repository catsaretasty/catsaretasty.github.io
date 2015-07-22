function embedSoundcloud(id) {
    var r = new XMLHttpRequest();
    r.onreadystatechange = function () {
        if (r.readyState === 4 && r.status === 200) {
            document.querySelector('#showcase').innerHTML = '<iframe width="100%" height="450" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/users/' + JSON.parse(r.responseText).id + '&amp;auto_play=false&amp;hide_related=false&amp;show_comments=true&amp;show_user=true&amp;show_reposts=false&amp;visual=true"></iframe>';
        }
    };

    r.open('GET', 'https://api.soundcloud.com/resolve?url=http://soundcloud.com/' + id + '&client_id=27b0c9c2c33ba40bcb06b6026112a568', true);
    r.send(null);
}