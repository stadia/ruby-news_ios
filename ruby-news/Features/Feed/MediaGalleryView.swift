import SDWebImageSwiftUI
import SwiftUI

/// 포스트의 이미지 첨부를 풀스크린 페이지 갤러리로 표시한다.
/// 좌우 스와이프(TabView)로 이미지 이동, 핀치/더블탭 줌, 줌 상태에서 패닝, 닫기 버튼.
struct MediaGalleryView: View {
    let attachments: [MediaAttachment]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(attachments: [MediaAttachment], startIndex: Int) {
        self.attachments = attachments
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(attachments.enumerated()), id: \.element.url) { index, attachment in
                    ZoomableImageView(url: attachment.url, resetToken: currentIndex)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.4), in: Circle())
            }
            .padding()
            .accessibilityLabel("닫기")
        }
        .overlay(alignment: .bottom) {
            if let caption = currentCaption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
    }

    private var currentCaption: String? {
        guard attachments.indices.contains(currentIndex) else { return nil }
        let name = attachments[currentIndex].name
        return name?.isEmpty == false ? name : nil
    }
}

/// 한 장의 원격 이미지를 핀치/더블탭 줌 + (줌 상태에서) 드래그 패닝으로 표시한다.
private struct ZoomableImageView: View {
    let url: URL
    /// 부모의 `currentIndex`. 값이 바뀌면(페이지 이동) 줌/오프셋을 초기화한다.
    let resetToken: Int

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
                .tint(.white)
        }
        .scaleEffect(scale)
        .offset(offset)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = min(max(lastScale * value, 1), 5)
                }
                .onEnded { _ in
                    lastScale = scale
                    if scale <= 1 { resetOffset() }
                }
        )
        // 줌 상태(scale > 1)에서만 드래그를 활성화해 패닝하고, 평상시에는
        // 비활성(`.subviews`)으로 두어 TabView 페이지 스와이프가 동작하게 한다.
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height)
                }
                .onEnded { _ in lastOffset = offset },
            including: scale > 1 ? .all : .subviews
        )
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if scale > 1 {
                    scale = 1
                    lastScale = 1
                    resetOffset()
                } else {
                    scale = 2
                    lastScale = 2
                }
            }
        }
        .onChange(of: resetToken) {
            scale = 1
            lastScale = 1
            resetOffset()
        }
    }

    private func resetOffset() {
        offset = .zero
        lastOffset = .zero
    }
}
