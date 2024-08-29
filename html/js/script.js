let cameras = {};
let locales = {};
let inRecordingMenu = false;

$(document).ready(function () {
    window.addEventListener('message', function (event) {
        const data = event.data
        
        cameras = data.cameras
        locales = data.locales

        if (cameras != undefined) {
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
    $('.container-camera-lists').empty();
    $('.container-header-top').text(locales[0]);
    $('.container-header-bottom').text(locales[1]);

    for (const index in cameras) {
        const index_ = cameras[index].cameras.id
        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${cameras[index].cameras.title}</p>
                    <p class="camera-description-bottom">${cameras[index].cameras.description}</p>
                </div>
                <div class="camera-position">
                    <p>${cameras[index].cameras.location}</p>
                    <p>Videos: ${cameras[index].cameras.videos.length}</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchCam(${index_})>Anschauen</button>
                    <button onclick=recordings(${index})>Aufnahmen</button>
                </div>
            </div>
        `
        $('.container-camera-lists').append(appendData);
    }

    
}

const watchCam = (id) => {        
    post("watchCam", id)
    cameras = {};
    videos  = {}; 
    document.body.style.display = "none"
}

const watchRecording = (camera, video) => {    
    post("watchRecording", camera, video + 1)
    cameras = {};
    videos  = {}; 
    document.body.style.display = "none"
}

const recordings = (i) => {

    inRecordingMenu = true;
    $('.container-camera-lists').empty();
    
    for (const index in cameras[i].cameras.videos) {
        const formattedDate = cameras[i].cameras.videos[index].replace(/(\d{2})\.(\d{2})\.(\d{4})_(\d{2})\.(\d{2})\.(\d{2})(?:\.json)?$/, '$3-$2-$1 $4:$5:$6');

        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${formattedDate}</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchRecording(${[i, index]})>Video anschauen</button>
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