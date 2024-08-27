let cameras = {};
let videos  = {};
let locales = {};
let inRecordingMenu = false;

$(document).ready(function () {
    window.addEventListener('message', function (event) {
        const data = event.data
        
        cameras = data.cameras
        videos  = data.videos
        locales = data.locales

        if (videos != undefined && cameras != undefined) {
            openMenu()
            $('.loader').css('display', 'none');
            $('._X_').css('display', 'block');
        } else {
            $('._X_').css('display', 'none');
            $('.loader').css('display', 'grid');
        }

        switch (data.action) {
            case 'open':
                $(document.body).fadeIn(125)
                break;
            case 'close':
                $(document.body).fadeOut(125)
                break;
        }
    });
});

const openMenu = () => {
    let index_ = 1;
    $('.container-camera-lists').empty();
    $('.container-header-top').text(locales[0]);
    $('.container-header-bottom').text(locales[1]);

    for (const index in cameras) {
        index_++;
        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${cameras[index].title}</p>
                    <p class="camera-description-bottom">${cameras[index].description}</p>
                </div>
                <div class="camera-position">
                    <p>Beverly Hills</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchCam(${index_})>Anschauen</button>
                    <button onclick=recordings(${index_})>Aufnahmen</button>
                </div>
            </div>
        `
        $('.container-camera-lists').append(appendData);
    }

    
}

const watchCam = (id) => {    
    post("watchCam", id)
}

const recordings = (id) => {
    inRecordingMenu = true;
    $('.container-camera-lists').empty();
    let index_ = 0;

    for (const index in videos) {
        index_++;
        
        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${videos[index].fileName}</p>
                </div>
                <div class="camera-position">
                    <p>Beverly Hills</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchCam(${index_})>Video anschauen</button>
                </div>
            </div>
        `
        $('.container-camera-lists').append(appendData);
    }

}

const closeMenu = () => {   
    if (inRecordingMenu) {
        openMenu()
        inRecordingMenu = false
        return
    }
    cameras = {};
    videos  = {}; 
    document.body.style.display = "none"
    post("close")
}

const post = (point, ...data) => {
    $.post(`https://${GetParentResourceName()}/${point}`, JSON.stringify(...data), function (msg) {});
}